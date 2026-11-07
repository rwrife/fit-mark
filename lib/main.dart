import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ride_notes.dart';
import 'ride_notes_view.dart';
import 'snapshots.dart';

void main() => runApp(const FitMarkApp());

class FitMarkApp extends StatelessWidget {
  const FitMarkApp({super.key});

  @override
  Widget build(BuildContext context) => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => const CupertinoApp(
      title: 'Fit Mark',
      home: AdaptiveHome(),
    ),
    TargetPlatform.windows => fluent.FluentApp(
      title: 'Fit Mark',
      home: const AdaptiveHome(),
    ),
    _ => MaterialApp(
      title: 'Fit Mark',
      theme: ThemeData(useMaterial3: true),
      home: const AdaptiveHome(),
    ),
  };
}

class AdaptiveHome extends StatefulWidget {
  const AdaptiveHome({super.key});

  @override
  State<AdaptiveHome> createState() => _AdaptiveHomeState();
}

class _AdaptiveHomeState extends State<AdaptiveHome> {
  int _selected = 0;
  final _history = SnapshotHistory([
    SetupSnapshot(
      id: 'setup',
      takenAt: DateTime.now().toUtc(),
      measurements: {},
    ),
  ]);
  late RideJournal _journal = RideJournal(histories: {'bike': _history});

  Widget get _page => _selected == 0
      ? const _SetupOverview()
      : RideNotesView(
          journal: _journal,
          bikeId: 'bike',
          snapshotId: 'setup',
          onAdd: (note) => setState(() => _journal = _journal.add(note)),
        );

  void _select(int index) => setState(() => _selected = index);

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 700;
    // ponytail: two journal destinations only; add bike selection in #6.
    final content = switch (platform) {
      TargetPlatform.windows => fluent.NavigationView(
        pane: fluent.NavigationPane(
          selected: _selected,
          onChanged: _select,
          displayMode: width >= 1008
              ? fluent.PaneDisplayMode.expanded
              : fluent.PaneDisplayMode.compact,
          items: [
            fluent.PaneItem(
              icon: const fluent.Icon(fluent.FluentIcons.home),
              title: const Text('Setup'),
              body: const _SetupOverview(),
            ),
            fluent.PaneItem(
              icon: const fluent.Icon(fluent.FluentIcons.edit_note),
              title: const Text('Ride notes'),
              body: _page,
            ),
          ],
        ),
        paneBodyBuilder: (item, body) => fluent.ScaffoldPage(
          header: const fluent.PageHeader(title: Text('Fit Mark')),
          content: Column(
            children: [
              fluent.CommandBar(
                primaryItems: [
                  fluent.CommandBarButton(
                    label: const Text('Setup'),
                    onPressed: () => _select(0),
                  ),
                  fluent.CommandBarButton(
                    label: const Text('Ride notes'),
                    onPressed: () => _select(1),
                  ),
                ],
              ),
              Expanded(child: body ?? const SizedBox.shrink()),
            ],
          ),
        ),
      ),
      TargetPlatform.iOS => CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(_selected == 0 ? 'Fit Mark · Setup' : 'Ride notes'),
        ),
        child: SafeArea(
          child: wide
              ? Row(
                  children: [
                    SizedBox(width: 220, child: _cupertinoSidebar()),
                    const VerticalDivider(width: 1),
                    Expanded(child: _page),
                  ],
                )
              : Column(
                  children: [
                    Expanded(child: _page),
                    CupertinoTabBar(
                      currentIndex: _selected,
                      onTap: _select,
                      items: const [
                        BottomNavigationBarItem(
                          icon: Icon(CupertinoIcons.gear),
                          label: 'Setup',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(CupertinoIcons.pencil),
                          label: 'Ride notes',
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
      _ => Scaffold(
        appBar: AppBar(title: const Text('Fit Mark')),
        body: wide
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: _selected,
                    onDestinationSelected: _select,
                    extended: width >= 1000,
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.pedal_bike),
                        label: Text('Setup'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.edit_note),
                        label: Text('Ride notes'),
                      ),
                    ],
                  ),
                  Expanded(child: _page),
                ],
              )
            : _page,
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: _selected,
                onDestinationSelected: _select,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.pedal_bike),
                    label: 'Setup',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.edit_note),
                    label: 'Ride notes',
                  ),
                ],
              ),
      ),
    };
    return Shortcuts(
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.digit1, control: true):
            const _SelectDestination(0),
        const SingleActivator(LogicalKeyboardKey.digit2, control: true):
            const _SelectDestination(1),
      },
      child: Actions(
        actions: {
          _SelectDestination: CallbackAction<_SelectDestination>(
            onInvoke: (intent) {
              _select(intent.index);
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: content),
      ),
    );
  }

  Widget _cupertinoSidebar() => ListView(
    children: [
      for (final (index, label, icon) in [
        (0, 'Setup', CupertinoIcons.gear),
        (1, 'Ride notes', CupertinoIcons.pencil),
      ])
        Semantics(
          selected: _selected == index,
          child: CupertinoButton(
            minimumSize: const Size(48, 48),
            onPressed: () => _select(index),
            child: Row(
              children: [
                Icon(icon),
                const SizedBox(width: 12),
                Expanded(child: Text(label)),
              ],
            ),
          ),
        ),
    ],
  );
}

class _SelectDestination extends Intent {
  const _SelectDestination(this.index);
  final int index;
}

class _SetupOverview extends StatelessWidget {
  const _SetupOverview();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: const [
      Text('Setup', style: TextStyle(fontSize: 24)),
      SizedBox(height: 12),
      Text(
        'No bikes saved yet. Bike editing and local storage are coming next.',
      ),
      SizedBox(height: 8),
      Text(
        'Record your own reference points and units. No fit or medical advice.',
      ),
    ],
  );
}
