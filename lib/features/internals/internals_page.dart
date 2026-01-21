import 'package:flutter/material.dart';

class InternalsPage extends StatelessWidget {
  const InternalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Internal Marks')),
      body: const Center(
        child: Text(
          'Internal Marks Coming Soon',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}
