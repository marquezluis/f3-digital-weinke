// lib/screens/q_builder_screen.dart
// Simple local workout builder for custom Weinkes.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/exercise_service.dart';
import '../services/current_workout_service.dart';
import '../services/q_builder_service.dart';

class QBuilderScreen extends StatefulWidget {
  const QBuilderScreen({super.key});

  @override
  State<QBuilderScreen> createState() => _QBuilderScreenState();
}

class _QBuilderScreenState extends State<QBuilderScreen> {
  int _duration = 45;
  String _intensity = 'Intermediate';
  String _equipment = 'Mixed (50/50)';
  String _focus = 'Full Body Grinder';
  String _format = 'Circuit';
  bool _simpleQMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: F3Colors.background,
      appBar: AppBar(
        title: const Text('Q Builder'),
        backgroundColor: F3Colors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: F3Colors.accent.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.landscape_rounded,
                      color: F3Colors.accent, size: 32),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    "Build a clear, runnable Weinke from time, equipment, fitness level, and format.",
                    style: TextStyle(
                      color: F3Colors.textSecondary,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Parameter 1: Time
            _buildSectionLabel('TIME (MINUTES)'),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: F3Colors.accent,
                thumbColor: F3Colors.accent,
                inactiveTrackColor: F3Colors.elevated,
              ),
              child: Slider(
                value: _duration.toDouble(),
                min: 30,
                max: 60,
                divisions: 2,
                label: '$_duration min',
                onChanged: (val) => setState(() => _duration = val.toInt()),
              ),
            ),
            Center(
              child: Text(
                '$_duration Minutes',
                style: const TextStyle(
                    color: F3Colors.textPrimary, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 24),

            // Parameter 2: Intensity
            _buildSectionLabel('FITNESS LEVEL (SCALE FOR FNGs)'),
            _buildDropdown(
              value: _intensity,
              items: [
                'Beginner Friendly',
                'Intermediate',
                'Advanced / Murph Prep'
              ],
              onChanged: (val) => setState(() => _intensity = val!),
            ),

            const SizedBox(height: 24),

            // Parameter 3: Equipment
            _buildSectionLabel('EQUIPMENT AVAILABLE'),
            _buildDropdown(
              value: _equipment,
              items: [
                'Bodyweight Only',
                'Coupons Required',
                'Mixed (50/50)',
                'Sandbags / Rucks'
              ],
              onChanged: (val) => setState(() => _equipment = val!),
            ),

            const SizedBox(height: 24),

            // Parameter 4: Focus
            _buildSectionLabel('BEATDOWN THEME'),
            _buildDropdown(
              value: _focus,
              items: [
                'Full Body Grinder',
                'Leg Day (Lt. Dan style)',
                'Upper Body / Shoulders',
                'Heavy Core (Mary)',
                'Advanced / Murph Prep',
                'Coupon Grinder',
                'Military PT / Smoke Session'
              ],
              onChanged: (val) => setState(() => _focus = val!),
            ),

            const SizedBox(height: 24),

            _buildSectionLabel('Q FORMAT'),
            _buildDropdown(
              value: _format,
              items: const [
                'Circuit',
                'AMRAP',
                'Tabata',
                'Dora',
                'Q Rescue',
              ],
              onChanged: (val) => setState(() => _format = val!),
            ),

            const SizedBox(height: 16),

            SwitchListTile(
              value: _simpleQMode,
              onChanged: (val) => setState(() => _simpleQMode = val),
              contentPadding: EdgeInsets.zero,
              activeThumbColor: F3Colors.accent,
              title: const Text(
                'Simple Q Mode',
                style: TextStyle(
                  color: F3Colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: const Text(
                'Fewer movements, easier transitions, clearer cadence.',
                style: TextStyle(color: F3Colors.textSecondary),
              ),
            ),

            const SizedBox(height: 48),

            // Generate Action
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Building your Weinke...')),
                  );

                  final exerciseSvc = context.read<ExerciseService>();
                  final workoutSvc = context.read<CurrentWorkoutService>();

                  final qBuilder = QBuilderService(exerciseSvc);
                  final result = qBuilder.buildBeatdown(QBuilderRequest(
                    durationMinutes: _duration,
                    intensity: _intensity,
                    equipment: _equipment,
                    focus: _focus,
                    format: _format,
                    simpleQMode: _simpleQMode,
                  ));

                  workoutSvc.setDraftPlan(result.plan);

                  final reviewLabel = result.review.hasWarnings
                      ? '${result.review.warnings.length} coaching note(s)'
                      : 'clean Q Builder review';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Built ${result.settings.format.displayName} · difficulty ${result.review.difficultyScore}/100 · $reviewLabel',
                      ),
                    ),
                  );

                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: F3Colors.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.build_rounded, color: Colors.white),
                label: const Text(
                  'BUILD CUSTOM BEATDOWN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Center(
              child: TextButton.icon(
                onPressed: () async {
                  final url = Uri.parse('https://f3nation.com/exicon/');
                  try {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } catch (_) {}
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('SEARCH OFFICIAL EXICON ONLINE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: const TextStyle(
          color: F3Colors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: F3Colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: F3Colors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: F3Colors.card,
          style: const TextStyle(color: F3Colors.textPrimary, fontSize: 16),
          icon: const Icon(Icons.arrow_drop_down_rounded,
              color: F3Colors.textSecondary),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
