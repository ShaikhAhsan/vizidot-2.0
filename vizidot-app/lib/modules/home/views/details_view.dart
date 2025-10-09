import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DetailsView extends StatelessWidget {
  const DetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: Center(
        child: FilledButton(
          onPressed: () => Get.back(),
          child: const Text('Go Back'),
        ),
      ),
    );
  }
}


