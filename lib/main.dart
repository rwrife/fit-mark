import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'backup_view.dart';
import 'domain.dart';
import 'local_store.dart';
import 'ride_notes.dart';
import 'ride_notes_view.dart';
import 'snapshots.dart';

void main() => runApp(const FitMarkApp());

class FitMarkApp extends StatelessWidget {
  final LocalStore? initialStore;
  const FitMarkApp({super.key, this.initialStore});

  @override
  Widget build(BuildContext context) => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => CupertinoApp(
      title: 'Fit Mark',
      home: AdaptiveHome(initialStore: initialStore),
    ),
    TargetPlatform.windows => fluent.FluentApp(
      title: 'Fit Mark',
      home: AdaptiveHome(initialStore: initialStore),
    ),
    _ => MaterialApp(
      title: 'Fit Mark',
      theme: ThemeData(useMaterial3: true),
      home: AdaptiveHome(initialStore: initialStore),
    ),
  };
}

class AdaptiveHome extends StatefulWidget {
  final LocalStore? initialStore;
  const AdaptiveHome({super.key, this.initialStore});

  // ponytail: test-only injection bypasses native path discovery in widget tests.

  @override
  State<AdaptiveHome> createState() => _AdaptiveHomeState();
}

class _AdaptiveHomeState extends State<AdaptiveHome> {
  int _selected = 0;
  LocalStore? _store;
  FitMarkData _data = FitMarkData();
  String? _loadError;
  final _history = SnapshotHistory([
    SetupSnapshot(id: 'setup', takenAt: DateTime.utc(2026), measurements: {}),
  ]);

  @override
  void initState() {
    super.initState();
    if (widget.initialStore case final store?) {
      _store = store;
      _data = store.load();
    } else {
      _openStore();
    }
  }

  Future<void> _openStore() async {
    try {
      final store = await LocalStore.open();
      final data = store.load();
      if (!mounted) {
        await store.close();
        return;
      }
      setState(() {
        _store = store;
        _data = data;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _loadError = 'Cannot open local journal: $error');
      }
    }
  }

  @override
  void dispose() {
    _store?.close();
    super.dispose();
  }

  Future<void> _addNote(RideNote note) async {
    final store = _store;
    if (store == null) return;
    try {
      final current = store.load();
      final bikes = {...current.bikes};
      final histories = {...current.histories};
      bikes.putIfAbsent(
        'bike',
        () => Bike(name: 'My bike', make: '', model: '', type: 'Bicycle'),
      );
      histories.putIfAbsent('bike', () => _history);
      final next = FitMarkData(
        bikes: bikes,
        histories: histories,
        notes: [...current.notes, note],
      );
      await store.save(next);
      if (mounted) setState(() => _data = next);
    } catch (error) {
      if (mounted) setState(() => _loadError = 'Cannot save ride note: $error');
    }
  }

  Widget get _page => _selected == 0
      ? const _SetupOverview()
      : _selected == 2
      ? BackupView(store: _store!)
      : RideNotesView(
          journal: RideJournal(
            histories: {
              ..._data.histories,
              if (!_data.histories.containsKey('bike')) 'bike': _history,
            },
            notes: _data.notes,
          ),
          bikeId: 'bike',
          snapshotId: 'setup',
          onAdd: _addNote,
        );

  void _select(int index) => setState(() {
    _selected = index;
    if (_store != null) _data = _store!.load();
  });

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) return Center(child: Text(_loadError!));
    if (_store == null) {
      return const Center(child: Text('Opening local journal…'));
    }
    final platform = defaultTargetPlatform;
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 700;
    // ponytail: single placeholder bike until bike editing lands.
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
            fluent.PaneItem(
              icon: const fluent.Icon(fluent.FluentIcons.save),
              title: const Text('Local backup'),
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
                  fluent.CommandBarButton(
                    label: const Text('Local backup'),
                    onPressed: () => _select(2),
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
          middle: Text(switch (_selected) {
            0 => 'Fit Mark · Setup',
            1 => 'Ride notes',
            _ => 'Local backup',
          }),
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
                        BottomNavigationBarItem(
                          icon: Icon(CupertinoIcons.archivebox),
                          label: 'Local backup',
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
                      NavigationRailDestination(
                        icon: Icon(Icons.save_alt),
                        label: Text('Local backup'),
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
                  NavigationDestination(
                    icon: Icon(Icons.save_alt),
                    label: 'Local backup',
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
        const SingleActivator(LogicalKeyboardKey.digit3, control: true):
            const _SelectDestination(2),
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
        (2, 'Local backup', CupertinoIcons.archivebox),
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
