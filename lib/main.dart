import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() => runApp(const FitMarkApp());

class FitMarkApp extends StatelessWidget {
  const FitMarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;
    const message = 'Bike profiles are not available yet.';
    if (platform == TargetPlatform.iOS) {
      return const CupertinoApp(
        title: 'Fit Mark',
        home: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(middle: Text('Fit Mark')),
          child: SafeArea(child: Center(child: Text(message))),
        ),
      );
    }
    return MaterialApp(
      title: 'Fit Mark',
      theme: ThemeData(useMaterial3: true),
      home: const Scaffold(
        appBar: _TitleBar(),
        body: Center(child: Text(message)),
      ),
    );
  }
}

class _TitleBar extends StatelessWidget implements PreferredSizeWidget {
  const _TitleBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(title: const Text('Fit Mark'));
}
