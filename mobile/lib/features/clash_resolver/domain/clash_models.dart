class MusicPreferences {
  const MusicPreferences({
    this.manualGenres = const [],
    this.manualArtists = const [],
    this.spotifyGenres = const [],
    this.spotifyArtists = const [],
  });

  final List<String> manualGenres;
  final List<String> manualArtists;
  final List<String> spotifyGenres;
  final List<String> spotifyArtists;

  bool get spotifyConnected =>
      spotifyGenres.isNotEmpty || spotifyArtists.isNotEmpty;

  factory MusicPreferences.fromJson(Map<String, dynamic> json) {
    List<String> values(String key) =>
        (json[key] as List? ?? const []).cast<String>();
    return MusicPreferences(
      manualGenres: values('manual_genres'),
      manualArtists: values('manual_artists'),
      spotifyGenres: values('spotify_genres'),
      spotifyArtists: values('spotify_artists'),
    );
  }

  Map<String, dynamic> toJson() => {
        'manual_genres': manualGenres,
        'manual_artists': manualArtists,
        'spotify_genres': spotifyGenres,
        'spotify_artists': spotifyArtists,
      };

  MusicPreferences withManual({
    required List<String> genres,
    required List<String> artists,
  }) {
    return MusicPreferences(
      manualGenres: genres,
      manualArtists: artists,
      spotifyGenres: spotifyGenres,
      spotifyArtists: spotifyArtists,
    );
  }
}

class ConcertOption {
  const ConcertOption({
    required this.id,
    required this.artist,
    required this.stage,
    required this.startsAt,
    required this.endsAt,
    required this.genres,
    this.voteCount = 0,
    this.votedByCurrentUser = false,
  });

  final String? id;
  final String artist;
  final String stage;
  final DateTime startsAt;
  final DateTime endsAt;
  final List<String> genres;
  final int voteCount;
  final bool votedByCurrentUser;

  factory ConcertOption.fromJson(Map<String, dynamic> json) => ConcertOption(
        id: json['id'] as String?,
        artist: json['artist'] as String,
        stage: json['stage'] as String,
        startsAt: DateTime.parse(json['starts_at'] as String).toLocal(),
        endsAt: DateTime.parse(json['ends_at'] as String).toLocal(),
        genres: (json['genres'] as List? ?? const []).cast<String>(),
        voteCount: json['vote_count'] as int? ?? 0,
        votedByCurrentUser: json['voted_by_current_user'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'artist': artist,
        'stage': stage,
        'starts_at': startsAt.toUtc().toIso8601String(),
        'ends_at': endsAt.toUtc().toIso8601String(),
        'genres': genres,
        'vote_count': voteCount,
        'voted_by_current_user': votedByCurrentUser,
      };

  ConcertOption copyWith({int? voteCount, bool? votedByCurrentUser}) {
    return ConcertOption(
      id: id,
      artist: artist,
      stage: stage,
      startsAt: startsAt,
      endsAt: endsAt,
      genres: genres,
      voteCount: voteCount ?? this.voteCount,
      votedByCurrentUser: votedByCurrentUser ?? this.votedByCurrentUser,
    );
  }
}

class ClashConflict {
  const ClashConflict({
    this.id = '',
    required this.startsAt,
    required this.endsAt,
    required this.options,
    this.decidedOptionId,
  });

  final String id;
  final DateTime startsAt;
  final DateTime endsAt;
  final List<ConcertOption> options;
  final String? decidedOptionId;
  int get totalVotes =>
      options.fold(0, (total, item) => total + item.voteCount);

  factory ClashConflict.fromJson(Map<String, dynamic> json) => ClashConflict(
        id: json['id'] as String? ?? '',
        startsAt: DateTime.parse(json['starts_at'] as String).toLocal(),
        endsAt: DateTime.parse(json['ends_at'] as String).toLocal(),
        options: (json['options'] as List)
            .map((value) =>
                ConcertOption.fromJson(Map<String, dynamic>.from(value as Map)))
            .toList(growable: false),
        decidedOptionId: json['decided_option_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'starts_at': startsAt.toUtc().toIso8601String(),
        'ends_at': endsAt.toUtc().toIso8601String(),
        'options': options.map((option) => option.toJson()).toList(),
        'decided_option_id': decidedOptionId,
      };

  ClashConflict copyWith({
    List<ConcertOption>? options,
    String? decidedOptionId,
  }) {
    return ClashConflict(
      id: id,
      startsAt: startsAt,
      endsAt: endsAt,
      options: options ?? this.options,
      decidedOptionId: decidedOptionId ?? this.decidedOptionId,
    );
  }
}

class ClashRecommendation {
  const ClashRecommendation({
    required this.selectedOptionId,
    required this.selectedArtist,
    required this.selectedStage,
    required this.score,
    required this.matchedGenres,
    required this.matchedArtist,
    required this.reason,
    this.offline = false,
    this.voteCount = 0,
  });

  final String? selectedOptionId;
  final String selectedArtist;
  final String selectedStage;
  final int score;
  final List<String> matchedGenres;
  final bool matchedArtist;
  final String reason;
  final bool offline;
  final int voteCount;

  factory ClashRecommendation.fromJson(Map<String, dynamic> json) =>
      ClashRecommendation(
        selectedOptionId: json['selected_option_id'] as String?,
        selectedArtist: json['selected_artist'] as String,
        selectedStage: json['selected_stage'] as String,
        score: json['score'] as int,
        matchedGenres:
            (json['matched_genres'] as List? ?? const []).cast<String>(),
        matchedArtist: json['matched_artist'] as bool? ?? false,
        reason: json['reason'] as String,
        offline: json['offline'] as bool? ?? false,
        voteCount: json['vote_count'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'selected_option_id': selectedOptionId,
        'selected_artist': selectedArtist,
        'selected_stage': selectedStage,
        'score': score,
        'matched_genres': matchedGenres,
        'matched_artist': matchedArtist,
        'reason': reason,
        'offline': offline,
        'vote_count': voteCount,
      };
}

class ClashSnapshot {
  const ClashSnapshot({
    required this.preferences,
    required this.conflicts,
    required this.festivalName,
    required this.recommendation,
    required this.fromCache,
    this.syncPending = false,
  });

  final MusicPreferences preferences;
  final List<ClashConflict> conflicts;
  final String? festivalName;
  final ClashRecommendation? recommendation;
  final bool fromCache;
  final bool syncPending;

  ClashSnapshot copyWith({
    MusicPreferences? preferences,
    List<ClashConflict>? conflicts,
    String? festivalName,
    ClashRecommendation? recommendation,
    bool? fromCache,
    bool? syncPending,
  }) {
    return ClashSnapshot(
      preferences: preferences ?? this.preferences,
      conflicts: conflicts ?? this.conflicts,
      festivalName: festivalName ?? this.festivalName,
      recommendation: recommendation ?? this.recommendation,
      fromCache: fromCache ?? this.fromCache,
      syncPending: syncPending ?? this.syncPending,
    );
  }

  static const empty = ClashSnapshot(
    preferences: MusicPreferences(),
    conflicts: [],
    festivalName: null,
    recommendation: null,
    fromCache: true,
  );
}
