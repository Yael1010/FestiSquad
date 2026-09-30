import 'package:flutter/material.dart';

// Shared, session-only summary of the squad selected by the signed-in user.
class SquadPreview {
  const SquadPreview(this.name, this.members, {this.id, this.code});
  final String name;
  final int members;
  final String? id;
  final String? code;
}

final activeSquadPreview =
    ValueNotifier(const SquadPreview('Sin squad activo', 0));
