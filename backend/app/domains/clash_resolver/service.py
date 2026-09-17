from app.domains.clash_resolver.schemas import RecommendationRequest, RecommendationResponse


class ClashResolverService:
    def recommend(self, payload: RecommendationRequest) -> RecommendationResponse:
        preferred_genres = {genre.lower() for genre in payload.spotify_genres + payload.manual_genres}
        favorite_artists = {artist.lower() for artist in payload.favorite_artists}

        best_option = None
        best_score = -1
        for option in payload.options:
            score = 0
            option_genres = {genre.lower() for genre in option.genres}
            score += len(option_genres & preferred_genres) * 3
            if option.artist.lower() in favorite_artists:
                score += 5
            if score > best_score:
                best_option = option
                best_score = score

        if best_option is None:
            raise ValueError("no_options")

        source = "Spotify y preferencias manuales" if payload.spotify_genres else "preferencias manuales"
        return RecommendationResponse(
            selected_artist=best_option.artist,
            selected_stage=best_option.stage,
            score=best_score,
            reason=f"Recomendación basada en {source}; fallback manual disponible.",
        )


clash_resolver_service = ClashResolverService()

