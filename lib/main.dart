import 'package:app/amostrador.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ECAC04());
}

class ECAC04 extends StatelessWidget {
  const ECAC04({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ECAC04',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red.shade800),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const ECAC04Home(),
        '/amostrador': (context) =>
            const AmostradorPage(title: 'Amostrador Padrão'),
      },
    );
  }
}

class ECAC04Home extends StatefulWidget {
  const ECAC04Home({super.key});

  @override
  State<ECAC04Home> createState() => _ECAC04HomeState();
}

class _ECAC04HomeState extends State<ECAC04Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ECAC04')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: FilledButton.icon(
              icon: const Icon(Icons.signal_wifi_4_bar),
              label: const Text('Amostrador'),
              onPressed: () => Navigator.pushNamed(context, '/amostrador'),
            ),
          ),
        ],
      ),
    );
  }
}
