import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../application/festival_catalog_controller.dart';
import '../data/festival_repository.dart';
import '../domain/festival.dart';

class FestivalAdminScreen extends ConsumerStatefulWidget {
  const FestivalAdminScreen({super.key});

  @override
  ConsumerState<FestivalAdminScreen> createState() =>
      _FestivalAdminScreenState();
}

class _FestivalAdminScreenState extends ConsumerState<FestivalAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _venue = TextEditingController();
  final _city = TextEditingController();
  final _officialUrl = TextEditingController();
  final _boundary = TextEditingController();
  final _stages = TextEditingController(text: '[]');
  final _schedule = TextEditingController(text: '[]');
  DateTime? _startsAt;
  DateTime? _endsAt;
  bool _publish = true;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _venue.dispose();
    _city.dispose();
    _officialUrl.dispose();
    _boundary.dispose();
    _stages.dispose();
    _schedule.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final initial = (start ? _startsAt : _endsAt) ??
        DateTime.now().add(Duration(days: start ? 30 : 31));
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: initial,
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    setState(() {
      final value =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (start) {
        _startsAt = value;
      } else {
        _endsAt = value;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startsAt == null || _endsAt == null || !_endsAt!.isAfter(_startsAt!)) {
      _message('Selecciona un periodo válido para el festival.');
      return;
    }
    try {
      final boundary = jsonDecode(_boundary.text) as Map<String, dynamic>;
      final stages = (jsonDecode(_stages.text) as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(growable: false);
      final schedule = (jsonDecode(_schedule.text) as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(growable: false);
      setState(() => _saving = true);
      final created = await ref.read(festivalRepositoryProvider).create(
            FestivalDraft(
              name: _name.text.trim(),
              venueName: _venue.text.trim(),
              city: _city.text.trim(),
              startsAt: _startsAt!,
              endsAt: _endsAt!,
              boundary: boundary,
              stages: stages,
              schedule: schedule,
              officialUrl: _officialUrl.text.trim().isEmpty
                  ? null
                  : _officialUrl.text.trim(),
              publish: _publish,
            ),
          );
      ref.invalidate(festivalCatalogControllerProvider);
      if (!mounted) return;
      context.go('/map?festivalId=${Uri.encodeQueryComponent(created.id)}');
    } catch (error) {
      _message(error is FormatException
          ? 'El GeoJSON o la lista de escenarios no tiene formato válido.'
          : apiErrorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _dateLabel(DateTime? value) {
    if (value == null) return 'Seleccionar';
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo festival')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            const Text(
              'Datos oficiales',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            _field(_name, 'Nombre del festival'),
            _field(_venue, 'Recinto'),
            _field(_city, 'Ciudad'),
            _field(
              _officialUrl,
              'Sitio oficial',
              required: false,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(start: true),
                    icon: const Icon(Icons.event),
                    label: Text('Inicio\n${_dateLabel(_startsAt)}'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(start: false),
                    icon: const Icon(Icons.event_available),
                    label: Text('Fin\n${_dateLabel(_endsAt)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Geometría GeoJSON',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            _field(
              _boundary,
              'Polígono del recinto',
              maxLines: 6,
            ),
            _field(
              _stages,
              'Escenarios',
              maxLines: 8,
            ),
            const SizedBox(height: 8),
            const Text(
              'Agenda del festival',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            _field(
              _schedule,
              'Horarios por escenario',
              maxLines: 10,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Publicar en el catálogo'),
              subtitle: const Text(
                'Desactiva para conservarlo como borrador.',
                style: TextStyle(color: FestiColors.muted),
              ),
              value: _publish,
              onChanged: (value) => setState(() => _publish = value),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.publish),
              label: const Text('Guardar festival'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = true,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                ? 'Este campo es obligatorio.'
                : null
            : null,
      ),
    );
  }
}
