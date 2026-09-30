class FestivalSummary {
  const FestivalSummary({
    required this.id,
    required this.name,
    required this.venueName,
    required this.city,
    required this.countryCode,
    required this.timezone,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.stageCount,
    this.imageUrl,
    this.officialUrl,
  });

  final String id;
  final String name;
  final String venueName;
  final String city;
  final String countryCode;
  final String timezone;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? imageUrl;
  final String? officialUrl;
  final String status;
  final int stageCount;

  factory FestivalSummary.fromJson(Map<String, dynamic> json) {
    return FestivalSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      venueName: json['venue_name'] as String,
      city: json['city'] as String,
      countryCode: json['country_code'] as String,
      timezone: json['timezone'] as String,
      startsAt: DateTime.parse(json['starts_at'] as String).toLocal(),
      endsAt: DateTime.parse(json['ends_at'] as String).toLocal(),
      imageUrl: json['image_url'] as String?,
      officialUrl: json['official_url'] as String?,
      status: json['status'] as String,
      stageCount: json['stage_count'] as int,
    );
  }
}

class FestivalDraft {
  const FestivalDraft({
    required this.name,
    required this.venueName,
    required this.city,
    required this.startsAt,
    required this.endsAt,
    required this.boundary,
    required this.stages,
    this.schedule = const [],
    this.countryCode = 'MX',
    this.timezone = 'America/Mexico_City',
    this.officialUrl,
    this.publish = false,
  });

  final String name;
  final String venueName;
  final String city;
  final String countryCode;
  final String timezone;
  final DateTime startsAt;
  final DateTime endsAt;
  final Map<String, dynamic> boundary;
  final List<Map<String, dynamic>> stages;
  final List<Map<String, dynamic>> schedule;
  final String? officialUrl;
  final bool publish;

  Map<String, dynamic> toJson() => {
        'name': name,
        'venue_name': venueName,
        'city': city,
        'country_code': countryCode,
        'timezone': timezone,
        'starts_at': startsAt.toUtc().toIso8601String(),
        'ends_at': endsAt.toUtc().toIso8601String(),
        'boundary': boundary,
        'stages': stages,
        'schedule': schedule,
        'official_url': officialUrl,
        'status': publish ? 'published' : 'draft',
      };
}
