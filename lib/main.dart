import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'ride_notes.dart';
import 'ride_notes_view.dart';
import 'snapshots.dart';

void main() => runApp(const FitMarkApp());

class FitMarkApp extends StatelessWidget {
  const FitMarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;
    if (platform == TargetPlatform.iOS) {
      return const CupertinoApp(
        title: 'Fit Mark',
        home: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(middle: Text('Fit Mark')),
          child: SafeArea(child: _Home()),
        ),
      );
    }
    return MaterialApp(
      title: 'Fit Mark',
      theme: ThemeData(useMaterial3: true),
      home: const Scaffold(appBar: _TitleBar(), body: _Home()),
    );
  }
}

class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  final _history = SnapshotHistory([
    SetupSnapshot(
      id: 'setup',
      takenAt: DateTime.now().toUtc(),
      measurements: {},
    ),
  ]);
  late RideJournal _journal = RideJournal(histories: {'bike': _history});

  @override
  Widget build(BuildContext context) => RideNotesView(
    journal: _journal,
    bikeId: 'bike',
    snapshotId: 'setup',
    onAdd: (note) => setState(() => _journal = _journal.add(note)),
  );
  // ponytail: sample setup lives only in memory; replace with bike/snapshot
  // selection and offline persistence in #5/#6.
}

class _TitleBar extends StatelessWidget implements PreferredSizeWidget {
  const _TitleBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(title: const Text('Fit Mark'));
}
