import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/router.dart';
import 'features/onboarding/data/onboarding_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Read the "seen onboarding" flag before the first frame so a new user
  // lands directly on onboarding (and a returning user directly on Today)
  // with no flash of the wrong screen in between.
  final onboardingDone = await OnboardingStorage.isCompleted();

  runApp(
    ProviderScope(
      child: HabitTrackerApp(
        router: createAppRouter(
          initialLocation: onboardingDone ? '/today' : '/onboarding',
        ),
      ),
    ),
  );
}