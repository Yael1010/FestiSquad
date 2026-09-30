class SquadSignalIdentity {
  const SquadSignalIdentity({
    required this.seed,
    required this.paletteIndex,
    required this.symbolIndex,
    required this.patternOffset,
  });

  final int seed;
  final int paletteIndex;
  final int symbolIndex;
  final int patternOffset;

  factory SquadSignalIdentity.fromCode(String code) {
    var hash = 0x811C9DC5;
    for (final unit in code.trim().toUpperCase().codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7FFFFFFF;
    }
    return SquadSignalIdentity(
      seed: hash,
      paletteIndex: hash % 6,
      symbolIndex: (hash ~/ 7) % 6,
      patternOffset: (hash ~/ 31) % 9,
    );
  }
}
