import 'package:flutter/material.dart';

/// Placeholder — replaces HabitKit's paywalled "Charts & Statistics".
/// Next step: pull completions per habit and render with fl_chart
/// (trend line + weekday breakdown bar chart).
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: const Center(child: Text('Charts coming soon')),
    );
  }
}
