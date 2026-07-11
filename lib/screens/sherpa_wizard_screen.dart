// lib/screens/spartan_wizard_screen.dart
// Backward-compatible wrapper for the old Spartan/Sherpa route/file name.
// New code should use QBuilderScreen from q_builder_screen.dart.

import 'package:flutter/material.dart';

import 'q_builder_screen.dart';

@Deprecated('Use QBuilderScreen instead.')
class SpartanWizardScreen extends StatelessWidget {
  const SpartanWizardScreen({super.key});

  @override
  Widget build(BuildContext context) => const QBuilderScreen();
}
