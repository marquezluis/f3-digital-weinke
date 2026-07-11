// lib/screens/custom_exercise_screen.dart
// Form to create custom exercises stored locally.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/exercise.dart';
import '../services/exercise_service.dart';
import '../theme/app_theme.dart';

class CustomExerciseScreen extends StatefulWidget {
  const CustomExerciseScreen({super.key});

  @override
  State<CustomExerciseScreen> createState() => _CustomExerciseScreenState();
}

class _CustomExerciseScreenState extends State<CustomExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _aliasesCtrl = TextEditingController();
  ExerciseCategory _category = ExerciseCategory.bodyweight;
  Equipment _equipment = Equipment.none;
  Intensity _intensity = Intensity.intermediate;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _aliasesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final aliases = _aliasesCtrl.text.trim().isEmpty
        ? <String>[]
        : _aliasesCtrl.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

    final exercise = Exercise(
      id: 'custom_${const Uuid().v4()}',
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      aliases: aliases,
      category: _category,
      equipment: _equipment,
      intensity: _intensity,
    );

    await context.read<ExerciseService>().addCustomExercise(exercise);

    if (mounted) {
      HapticFeedback.mediumImpact();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('"${exercise.name}" added to the Exicon!'),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: F3Colors.background,
      appBar: AppBar(
        title: const Text('Create Exercise'),
        backgroundColor: F3Colors.background,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'ADD CUSTOM EXERCISE',
              style: TextStyle(
                color: F3Colors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your exercise is stored locally and available for beatdown generation.',
              style: TextStyle(color: F3Colors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _field(
              controller: _nameCtrl,
              label: 'Exercise Name *',
              hint: 'e.g. Tunnel of Love',
              icon: Icons.fitness_center_rounded,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _descCtrl,
              label: 'Description',
              hint: 'How to perform this exercise',
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _aliasesCtrl,
              label: 'Aliases (comma-separated)',
              hint: 'e.g. Merkin, Push-up',
              icon: Icons.label_rounded,
            ),
            const SizedBox(height: 20),
            _sectionLabel('CATEGORY'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ExerciseCategory.values.map((cat) {
                final selected = _category == cat;
                final color = F3Colors.forCategory(cat.name);
                return ChoiceChip(
                  label: Text(cat.displayName),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    _category = cat;
                    if (cat == ExerciseCategory.coupon) {
                      _equipment = Equipment.coupon;
                    } else {
                      _equipment = Equipment.none;
                    }
                  }),
                  selectedColor: color.withValues(alpha: 0.2),
                  backgroundColor: F3Colors.card,
                  labelStyle: TextStyle(
                    color: selected ? color : F3Colors.textSecondary,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  side: BorderSide(
                    color: selected ? color : F3Colors.divider,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _sectionLabel('INTENSITY'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: Intensity.values.map((lvl) {
                final selected = _intensity == lvl;
                final color = F3Colors.forIntensity(lvl.name);
                return ChoiceChip(
                  label: Text(lvl.displayName),
                  selected: selected,
                  onSelected: (_) => setState(() => _intensity = lvl),
                  selectedColor: color.withValues(alpha: 0.2),
                  backgroundColor: F3Colors.card,
                  labelStyle: TextStyle(
                    color: selected ? color : F3Colors.textSecondary,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  side: BorderSide(
                    color: selected ? color : F3Colors.divider,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: F3Colors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.add_rounded),
                label: Text(_saving ? 'SAVING…' : 'ADD TO EXICON'),
              ),
            ),
            const SizedBox(height: 20),
            // List custom exercises already created
            Consumer<ExerciseService>(
              builder: (_, svc, __) {
                final customs = svc.customExercises;
                if (customs.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(color: F3Colors.divider),
                    const SizedBox(height: 8),
                    _sectionLabel('YOUR CUSTOM EXERCISES'),
                    const SizedBox(height: 8),
                    ...customs.map((ex) => _CustomExerciseTile(ex: ex)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: F3Colors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: F3Colors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: F3Colors.textSecondary, fontSize: 13),
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
      ),
      validator: validator,
    );
  }
}

class _CustomExerciseTile extends StatelessWidget {
  final Exercise ex;
  const _CustomExerciseTile({required this.ex});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: F3Colors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: F3Colors.divider),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ex.name,
                  style: const TextStyle(
                      color: F3Colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              Text('${ex.category.displayName} · ${ex.intensity.displayName}',
                  style: const TextStyle(
                      color: F3Colors.textSecondary, fontSize: 12)),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: F3Colors.textMuted, size: 20),
            onPressed: () async {
              await context.read<ExerciseService>().deleteCustomExercise(ex.id);
            },
          ),
        ]),
      ),
    );
  }
}
