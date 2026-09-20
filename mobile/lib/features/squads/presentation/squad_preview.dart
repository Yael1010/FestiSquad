import 'package:flutter/material.dart';

// Shared, session-only state for the interface demonstration.
class SquadPreview {
  const SquadPreview(this.name, this.members, {this.id, this.code});
  final String name;
  final int members;
  final String? id;
  final String? code;
}

final activeSquadPreview =
    ValueNotifier(const SquadPreview("Headliners ’26", 5));
