import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'local_store.dart';

class BackupView extends StatefulWidget {
  final LocalStore store;
  const BackupView({super.key, required this.store});

  @override
  State<BackupView> createState() => _BackupViewState();
}

class _BackupViewState extends State<BackupView> {
  FitMarkData? _preview;
  String? _error;
  bool _busy = false;

  Future<void> _import() async {
    setState(() {
      _busy = true;
      _error = null;
      _preview = null;
    });
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.length > 10 * 1024 * 1024) {
        throw const FormatException('Backup exceeds 10 MB');
      }
      final parsed = FitMarkData.importJson(utf8.decode(bytes));
      if (mounted) setState(() => _preview = parsed);
    } catch (error) {
      if (mounted) setState(() => _error = 'Import failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export({bool sheet = false}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = widget.store.load();
      final text = sheet
          ? data.bikes.keys.map(data.setupSheet).join('\n')
          : data.exportJson();
      await FilePicker.saveFile(
        fileName: sheet ? 'fit-mark-setup.txt' : 'fit-mark-backup.json',
        bytes: Uint8List.fromList(utf8.encode(text)),
        mimeType: sheet ? 'text/plain' : 'application/json',
      );
    } catch (error) {
      if (mounted) setState(() => _error = 'Export failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    final preview = _preview;
    if (preview == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.store.save(preview);
      if (mounted) setState(() => _preview = null);
    } catch (error) {
      if (mounted) setState(() => _error = 'Restore failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    final windows = defaultTargetPlatform == TargetPlatform.windows;
    Widget button(String title, VoidCallback? action) => windows
        ? fluent.Button(onPressed: action, child: Text(title))
        : ios
        ? CupertinoButton(onPressed: action, child: Text(title))
        : OutlinedButton(onPressed: action, child: Text(title));
    final current = widget.store.load();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Local backup', style: TextStyle(fontSize: 24)),
        const Text(
          'Files you export may contain personal ride notes. Keep them private. Import replaces all local data after confirmation.',
        ),
        button('Export JSON backup', _busy ? null : _export),
        button('Export setup sheet', _busy ? null : () => _export(sheet: true)),
        button('Preview JSON import', _busy ? null : _import),
        if (_preview != null) ...[
          Text(
            'Replace ${current.bikes.length} bikes, ${current.histories.values.fold<int>(0, (sum, h) => sum + h.snapshots.length)} snapshots, ${current.notes.length} ride notes with ${_preview!.bikes.length} bikes, ${_preview!.histories.values.fold<int>(0, (sum, h) => sum + h.snapshots.length)} snapshots, ${_preview!.notes.length} ride notes?',
          ),
          button(
            'Cancel import',
            _busy ? null : () => setState(() => _preview = null),
          ),
          button('Confirm replace all local data', _busy ? null : _confirm),
        ],
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Color(0xffba1a1a))),
      ],
    );
  }
}
