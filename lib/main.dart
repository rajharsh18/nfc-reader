import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_shell.dart';
import 'theme.dart';
import 'vault.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(GateKeyApp(vault: Vault(prefs)));
}

class GateKeyApp extends StatelessWidget {
  const GateKeyApp({required this.vault, super.key});

  final Vault vault;

  @override
  Widget build(BuildContext context) {
    return VaultScope(
      vault: vault,
      child: MaterialApp(
        title: 'GateKey',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const HomeShell(),
      ),
    );
  }
}
