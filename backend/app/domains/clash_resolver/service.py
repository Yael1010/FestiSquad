from collections import defaultdict
from datetime import datetime
from decimal import Decimal
from hashlib import sha256
from uuid import UUID

from sqlalchemy import delete, func, select, text
from sqlalchemy.orm import Session

from app.domains.clash_resolver.db_models import (
    Artist,
    ClashDecision,
    ClashVote,
    Genre,
    MusicArtistPreference,
    MusicPreference,
)
from app.domains.clash_resolver.schemas import (
    ConcertOption,
    ConflictGroup,
    ConflictListResponse,
    ClashDecisionRequest,
    ClashVoteRequest,
    MusicPreferencesResponse,
    RecommendationRequest,
    RecommendationResponse,
)
from app.domains.squads.db_models import SquadMember


def _key(value: str) -> str:
    return " ".join(value.strip().split()).casefold()


def group_conflicts(options: list[ConcertOption]) -> list[ConflictGroup]:
    candidates: dict[frozenset[UUID], list[ConcertOption]] = {}
    for boundary in sorted({option.starts_at for option in options}):
        active = [
            option
            for option in options
            if option.starts_at <= boundary < option.ends_at
        ]
        if len(active) >= 2:
            key = frozenset(option.id for option in active if option.id is not None)
            candidates[key] = active
    maximal = {
        key: value
        for key, value in candidates.items()
        if not any(key < other for other in candidates)
    }
    return [
        ConflictGroup(
            id=_conflict_id(group_options),
            starts_at=max(item.starts_at for item in group_options),
            ends_at=min(item.ends_at for item in group_options),
            options=group_options,
        )
        for _, group_options in sorted(
            maximal.items(),
            key=lambda item: min(option.starts_at for option in item[1]),
        )
    ]


def _conflict_id(options: list[ConcertOption]) -> str:
    identity = "|".join(sorted(str(option.id) for option in options))
    return sha256(identity.encode("ascii")).hexdigest()


class ClashResolverService:
    def recommend(self, payload: RecommendationRequest) -> RecommendationResponse:
        genre_weights = defaultdict(
            int, {_key(name): weight for name, weight in payload.genre_weights.items()}
        )
        artist_weights = defaultdict(
            int, {_key(name): weight for name, weight in payload.artist_weights.items()}
        )
        for genre in payload.manual_genres:
            genre_weights[_key(genre)] += 3
        for genre in payload.spotify_genres:
            genre_weights[_key(genre)] += 2
        for artist in payload.favorite_artists:
            artist_weights[_key(artist)] += 5

        ranked: list[
            tuple[int, datetime, str, ConcertOption, list[str], bool, int]
        ] = []
        for option in payload.options:
            matched_genres = sorted(
                genre for genre in option.genres if _key(genre) in genre_weights
            )
            score = sum(genre_weights[_key(genre)] for genre in matched_genres)
            matched_artist = _key(option.artist) in artist_weights
            if matched_artist:
                score += artist_weights[_key(option.artist)]
            vote_count = payload.option_vote_weights.get(str(option.id), 0)
            score += vote_count * 4
            ranked.append(
                (
                    -score,
                    option.starts_at,
                    _key(option.artist),
                    option,
                    matched_genres,
                    matched_artist,
                    vote_count,
                )
            )

        ranked.sort(key=lambda item: item[:3])
        _, _, _, selected, matched_genres, matched_artist, vote_count = ranked[0]
        score = -ranked[0][0]
        if matched_artist and matched_genres:
            reason = f"{selected.artist} coincide con artistas y géneros preferidos del squad."
        elif matched_artist:
            reason = f"{selected.artist} está entre los artistas preferidos del squad."
        elif matched_genres:
            reason = "Coincide con los géneros: " + ", ".join(matched_genres) + "."
        else:
            reason = (
                "No hubo coincidencias; se eligió la opción más temprana "
                "de forma determinista."
            )
        if vote_count:
            reason += f" Además, recibió {vote_count} voto(s) del squad."
        return RecommendationResponse(
            selected_option_id=selected.id,
            selected_artist=selected.artist,
            selected_stage=selected.stage,
            score=score,
            matched_genres=matched_genres,
            matched_artist=matched_artist,
            reason=reason,
            vote_count=vote_count,
        )

    def save_preferences(
        self,
        db: Session,
        user_id: UUID,
        genres: list[str],
        artists: list[str],
        source: str,
    ) -> MusicPreferencesResponse:
        if source not in {"manual", "spotify"}:
            raise ValueError("invalid_preference_source")
        db.execute(
            delete(MusicPreference).where(
                MusicPreference.user_id == user_id,
                MusicPreference.source == source,
            )
        )
        db.execute(
            delete(MusicArtistPreference).where(
                MusicArtistPreference.user_id == user_id,
                MusicArtistPreference.source == source,
            )
        )
        for position, name in enumerate(genres):
            normalized = _key(name)
            genre = db.scalar(select(Genre).where(Genre.name == normalized))
            if genre is None:
                genre = Genre(name=normalized)
                db.add(genre)
                db.flush()
            db.add(
                MusicPreference(
                    user_id=user_id,
                    genre_id=genre.id,
                    source=source,
                    weight=Decimal(max(1, 10 - position)),
                )
            )
        for position, name in enumerate(artists):
            normalized = " ".join(name.strip().split())
            artist = db.scalar(select(Artist).where(Artist.name == normalized))
            if artist is None:
                artist = Artist(name=normalized)
                db.add(artist)
                db.flush()
            db.add(
                MusicArtistPreference(
                    user_id=user_id,
                    artist_id=artist.id,
                    source=source,
                    weight=Decimal(max(1, 10 - position)),
                )
            )
        db.commit()
        return self.preferences(db, user_id)

    def preferences(self, db: Session, user_id: UUID) -> MusicPreferencesResponse:
        genres = db.execute(
            select(Genre.name, MusicPreference.source)
            .join(MusicPreference, MusicPreference.genre_id == Genre.id)
            .where(MusicPreference.user_id == user_id)
            .order_by(MusicPreference.weight.desc(), Genre.name)
        ).all()
        artists = db.execute(
            select(Artist.name, MusicArtistPreference.source)
            .join(MusicArtistPreference, MusicArtistPreference.artist_id == Artist.id)
            .where(MusicArtistPreference.user_id == user_id)
            .order_by(MusicArtistPreference.weight.desc(), Artist.name)
        ).all()
        return MusicPreferencesResponse(
            manual_genres=[name for name, source in genres if source == "manual"],
            spotify_genres=[name for name, source in genres if source == "spotify"],
            manual_artists=[name for name, source in artists if source == "manual"],
            spotify_artists=[name for name, source in artists if source == "spotify"],
        )

    def recommend_for_squad(
        self, db: Session, user_id: UUID, payload: RecommendationRequest
    ) -> RecommendationResponse:
        squad_id = UUID(str(payload.squad_id))
        self._require_member(db, squad_id, user_id)
        genre_rows = db.execute(
            text(
                "SELECT g.name, "
                "SUM(CASE WHEN mp.source = 'manual' THEN 3 ELSE 2 END) AS weight "
                "FROM dbo.music_preferences mp "
                "JOIN dbo.genres g ON g.id = mp.genre_id "
                "JOIN dbo.squad_members sm ON sm.user_id = mp.user_id "
                "WHERE sm.squad_id = :squad_id GROUP BY g.name"
            ),
            {"squad_id": str(squad_id)},
        ).all()
        artist_rows = db.execute(
            text(
                "SELECT a.name, "
                "SUM(CASE WHEN mapref.source = 'manual' THEN 5 ELSE 4 END) AS weight "
                "FROM dbo.music_artist_preferences mapref "
                "JOIN dbo.artists a ON a.id = mapref.artist_id "
                "JOIN dbo.squad_members sm ON sm.user_id = mapref.user_id "
                "WHERE sm.squad_id = :squad_id GROUP BY a.name"
            ),
            {"squad_id": str(squad_id)},
        ).all()
        option_ids = [option.id for option in payload.options if option.id is not None]
        vote_rows = db.execute(
            select(ClashVote.schedule_item_id, func.count())
            .where(
                ClashVote.squad_id == squad_id,
                ClashVote.schedule_item_id.in_(option_ids),
            )
            .group_by(ClashVote.schedule_item_id)
        ).all()
        enriched = payload.model_copy(
            update={
                "genre_weights": {name: int(weight) for name, weight in genre_rows},
                "artist_weights": {name: int(weight) for name, weight in artist_rows},
                "manual_genres": [],
                "spotify_genres": [],
                "favorite_artists": [],
                "option_vote_weights": {
                    str(option_id): int(count) for option_id, count in vote_rows
                },
            }
        )
        return self.recommend(enriched)

    def conflicts(
        self,
        db: Session,
        user_id: UUID,
        festival_id: UUID | None,
        squad_id: UUID | None = None,
    ) -> ConflictListResponse:
        if squad_id is not None:
            self._require_member(db, squad_id, user_id)
        festival = db.execute(
            text(
                "SELECT TOP 1 f.id, f.name FROM dbo.festivals f "
                "WHERE (:festival_id IS NULL OR f.id = :festival_id) "
                "ORDER BY CASE WHEN f.ends_at >= SYSUTCDATETIME() THEN 0 ELSE 1 END, "
                "f.starts_at"
            ),
            {"festival_id": str(festival_id) if festival_id else None},
        ).first()
        if festival is None:
            return ConflictListResponse(
                festival_id=None, festival_name=None, conflicts=[]
            )
        rows = db.execute(
            text(
                "SELECT si.id, si.artist_name, s.name, si.starts_at, si.ends_at, "
                "STRING_AGG(g.name, ',') WITHIN GROUP (ORDER BY g.name) AS genres "
                "FROM dbo.schedule_items si JOIN dbo.stages s ON s.id = si.stage_id "
                "LEFT JOIN dbo.schedule_item_genres sig ON sig.schedule_item_id = si.id "
                "LEFT JOIN dbo.genres g ON g.id = sig.genre_id "
                "WHERE s.festival_id = :festival_id "
                "GROUP BY si.id, si.artist_name, s.name, si.starts_at, si.ends_at "
                "ORDER BY si.starts_at, si.artist_name"
            ),
            {"festival_id": str(festival[0])},
        ).all()
        options = [
            ConcertOption(
                id=row[0],
                artist=row[1],
                stage=row[2],
                starts_at=row[3],
                ends_at=row[4],
                genres=row[5].split(",") if row[5] else [],
            )
            for row in rows
        ]
        groups = group_conflicts(options)
        if squad_id is not None and groups:
            option_ids = [option.id for option in options if option.id is not None]
            votes = db.execute(
                select(ClashVote.schedule_item_id, ClashVote.user_id).where(
                    ClashVote.squad_id == squad_id,
                    ClashVote.schedule_item_id.in_(option_ids),
                )
            ).all()
            counts: dict[UUID, int] = defaultdict(int)
            own_votes: set[UUID] = set()
            for option_id, voter_id in votes:
                counts[option_id] += 1
                if voter_id == user_id:
                    own_votes.add(option_id)
            decisions = {
                decision.conflict_id: decision.schedule_item_id
                for decision in db.scalars(
                    select(ClashDecision).where(ClashDecision.squad_id == squad_id)
                )
            }
            groups = [
                group.model_copy(
                    update={
                        "decided_option_id": decisions.get(group.id),
                        "options": [
                            option.model_copy(
                                update={
                                    "vote_count": counts.get(option.id, 0),
                                    "voted_by_current_user": option.id in own_votes,
                                }
                            )
                            for option in group.options
                        ],
                    }
                )
                for group in groups
            ]
        return ConflictListResponse(
            festival_id=festival[0], festival_name=festival[1], conflicts=groups
        )

    def vote(
        self, db: Session, user_id: UUID, payload: ClashVoteRequest
    ) -> ConflictListResponse:
        self._require_member(db, payload.squad_id, user_id)
        festival_id, group = self._required_conflict(
            db, user_id, payload.squad_id, payload.conflict_id, payload.option_id
        )
        option_ids = [option.id for option in group.options]
        db.execute(
            delete(ClashVote).where(
                ClashVote.squad_id == payload.squad_id,
                ClashVote.user_id == user_id,
                ClashVote.schedule_item_id.in_(option_ids),
            )
        )
        if payload.selected:
            db.add(
                ClashVote(
                    squad_id=payload.squad_id,
                    schedule_item_id=payload.option_id,
                    user_id=user_id,
                )
            )
        db.commit()
        return self.conflicts(db, user_id, festival_id, payload.squad_id)

    def decide(
        self, db: Session, user_id: UUID, payload: ClashDecisionRequest
    ) -> ConflictListResponse:
        membership = self._require_member(db, payload.squad_id, user_id)
        if membership.role != "admin":
            raise PermissionError("admin_required")
        festival_id, _ = self._required_conflict(
            db, user_id, payload.squad_id, payload.conflict_id, payload.option_id
        )
        decision = db.get(ClashDecision, (payload.squad_id, payload.conflict_id))
        if decision is None:
            decision = ClashDecision(
                squad_id=payload.squad_id,
                conflict_id=payload.conflict_id,
                schedule_item_id=payload.option_id,
                decided_by_user_id=user_id,
            )
            db.add(decision)
        else:
            decision.schedule_item_id = payload.option_id
            decision.decided_by_user_id = user_id
            decision.decided_at = datetime.utcnow()
        db.commit()
        return self.conflicts(db, user_id, festival_id, payload.squad_id)

    def _required_conflict(
        self,
        db: Session,
        user_id: UUID,
        squad_id: UUID,
        conflict_id: str,
        option_id: UUID,
    ) -> tuple[UUID, ConflictGroup]:
        reference_id = option_id
        festival_id = db.scalar(
            text(
                "SELECT s.festival_id FROM dbo.schedule_items si "
                "JOIN dbo.stages s ON s.id = si.stage_id WHERE si.id = :item_id"
            ),
            {"item_id": str(reference_id)},
        )
        if festival_id is None:
            raise ValueError("option_not_found")
        agenda = self.conflicts(db, user_id, festival_id, squad_id)
        group = next((item for item in agenda.conflicts if item.id == conflict_id), None)
        if group is None or (
            option_id is not None
            and option_id not in {option.id for option in group.options}
        ):
            raise ValueError("conflict_not_found")
        return UUID(str(festival_id)), group

    def _require_member(
        self, db: Session, squad_id: UUID, user_id: UUID
    ) -> SquadMember:
        membership = db.get(SquadMember, (squad_id, user_id))
        if membership is None:
            raise PermissionError("not_squad_member")
        return membership


clash_resolver_service = ClashResolverService()
