import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'ride_notes.dart';

/// Bike-scoped ride feedback. Caller owns persistence and snapshot selection.
class RideNotesView extends StatelessWidget {
  final RideJournal journal;
  final String bikeId;
  final String snapshotId;
  final ValueChanged<RideNote> onAdd;

  const RideNotesView({
    super.key,
    required this.journal,
    required this.bikeId,
    required this.snapshotId,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final notes = journal.forBike(bikeId, snapshotId: snapshotId);
    final platform = defaultTargetPlatform;
    final ios = platform == TargetPlatform.iOS;
    final windows = platform == TargetPlatform.windows;
    final items = <Widget>[
      const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Ride impressions only. No fit or medical advice.'),
      ),
      for (final note in notes)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Semantics(
            label:
                'Ride ${note.riddenAt.toLocal().toIso8601String()}, comfort ${note.comfort} of 5, ${note.terrain}: ${note.impressions}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${note.riddenAt.toLocal().year}-${note.riddenAt.toLocal().month.toString().padLeft(2, '0')}-${note.riddenAt.toLocal().day.toString().padLeft(2, '0')} · Comfort ${note.comfort}/5',
                ),
                Text(
                  note.terrain.isEmpty ? 'Terrain not recorded' : note.terrain,
                ),
                Text(note.impressions),
              ],
            ),
          ),
        ),
      if (notes.isEmpty)
        const Center(child: Text('No ride notes for this setup yet.')),
    ];
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text('Ride notes', style: TextStyle(fontSize: 22)),
        ),
        SizedBox(
          height: 48,
          child: windows
              ? fluent.Button(
                  onPressed: () => _openEditor(context),
                  child: const Text('Add ride note'),
                )
              : ios
              ? CupertinoButton(
                  onPressed: () => _openEditor(context),
                  child: const Text('Add ride note'),
                )
              : ElevatedButton(
                  onPressed: () => _openEditor(context),
                  child: const Text('Add ride note'),
                ),
        ),
        Expanded(child: ListView(children: items)),
      ],
    );
  }

  void _openEditor(BuildContext context) {
    final platform = defaultTargetPlatform;
    if (platform == TargetPlatform.windows) {
      Navigator.of(context).push(
        fluent.FluentPageRoute<void>(
          builder: (context) => fluent.NavigationView(
            content: fluent.ScaffoldPage(
              header: const fluent.PageHeader(title: Text('New ride note')),
              content: RideNoteEditor(
                bikeId: bikeId,
                snapshotId: snapshotId,
                onAdd: onAdd,
              ),
            ),
          ),
        ),
      );
    } else if (platform == TargetPlatform.iOS) {
      Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (context) => CupertinoPageScaffold(
            navigationBar: const CupertinoNavigationBar(
              middle: Text('New ride note'),
            ),
            child: SafeArea(
              child: RideNoteEditor(
                bikeId: bikeId,
                snapshotId: snapshotId,
                onAdd: onAdd,
              ),
            ),
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('New ride note')),
            body: RideNoteEditor(
              bikeId: bikeId,
              snapshotId: snapshotId,
              onAdd: onAdd,
            ),
          ),
        ),
      );
    }
  }
}

class RideNoteEditor extends StatefulWidget {
  final String bikeId;
  final String snapshotId;
  final ValueChanged<RideNote> onAdd;

  const RideNoteEditor({
    super.key,
    required this.bikeId,
    required this.snapshotId,
    required this.onAdd,
  });

  @override
  State<RideNoteEditor> createState() => _RideNoteEditorState();
}

class _RideNoteEditorState extends State<RideNoteEditor> {
  final _terrain = TextEditingController();
  final _impressions = TextEditingController();
  final _duration = TextEditingController();
  final _distance = TextEditingController();
  int _comfort = 3;
  String? _error;

  @override
  void dispose() {
    _terrain.dispose();
    _impressions.dispose();
    _duration.dispose();
    _distance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    final windows = defaultTargetPlatform == TargetPlatform.windows;
    Widget input(
      String label,
      TextEditingController controller, {
      bool numeric = false,
    }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ios
          ? CupertinoTextField(
              controller: controller,
              placeholder: label,
              keyboardType: numeric
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
            )
          : windows
          ? fluent.TextBox(
              controller: controller,
              placeholder: label,
              keyboardType: numeric
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
            )
          : TextField(
              controller: controller,
              decoration: InputDecoration(labelText: label),
              keyboardType: numeric
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
            ),
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Your own impressions, not a fit recommendation.'),
        input('Terrain', _terrain),
        input('Duration (minutes, optional)', _duration, numeric: true),
        input('Distance (km, optional)', _distance, numeric: true),
        input('Ride impressions', _impressions),
        const Text('Comfort (1 uncomfortable – 5 comfortable)'),
        for (final rating in [1, 2, 3, 4, 5])
          ios || windows
              ? ios
                    ? CupertinoButton(
                        onPressed: () => setState(() => _comfort = rating),
                        child: Text(
                          'Comfort $rating${rating == _comfort ? ' selected' : ''}',
                        ),
                      )
                    : fluent.Button(
                        onPressed: () => setState(() => _comfort = rating),
                        child: Text(
                          'Comfort $rating${rating == _comfort ? ' selected' : ''}',
                        ),
                      )
              : RadioGroup<int>(
                  groupValue: _comfort,
                  onChanged: (value) {
                    if (value != null) setState(() => _comfort = value);
                  },
                  child: RadioListTile<int>(
                    title: Text('Comfort $rating'),
                    value: rating,
                  ),
                ),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Color(0xffba1a1a))),
        windows
            ? fluent.FilledButton(
                onPressed: _save,
                child: const Text('Save ride note'),
              )
            : ios
            ? CupertinoButton.filled(
                onPressed: _save,
                child: const Text('Save ride note'),
              )
            : ElevatedButton(
                onPressed: _save,
                child: const Text('Save ride note'),
              ),
      ],
    );
  }

  void _save() {
    try {
      final duration = _duration.text.trim().isEmpty
          ? null
          : int.parse(_duration.text.trim());
      final distance = _distance.text.trim().isEmpty
          ? null
          : double.parse(_distance.text.trim());
      final now = DateTime.now().toUtc();
      final note = RideNote(
        id: '${now.microsecondsSinceEpoch}-${Random.secure().nextInt(0x7fffffff)}',
        bikeId: widget.bikeId,
        snapshotId: widget.snapshotId,
        riddenAt: now,
        durationMinutes: duration,
        distanceKm: distance,
        comfort: _comfort,
        terrain: _terrain.text,
        impressions: _impressions.text,
      );
      widget.onAdd(note);
      Navigator.of(context).pop();
    } on FormatException catch (error) {
      setState(() => _error = error.message);
    }
  }
}
