import 'package:flutter/material.dart';

class AddStudentPage extends StatelessWidget {
  const AddStudentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Student')),
      body: const Center(child: Text('Add Student Page Content')),
    );
  }
}
