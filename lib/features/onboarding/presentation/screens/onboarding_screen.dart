import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme_palette.dart';
import '../../../../app/theme/color_schemes.dart' show AppColors, LuxColors;
import '../../../../app/theme/theme_settings_provider.dart';
import '../../../habits/presentation/widgets/month_calendar.dart' show editableWindowDays;
import '../../data/onboarding_storage.dart';

/// First-run walkthrough. Shown automatically once (see main.dart), and can
/// be replayed any time from Settings > Show Onboarding with [isReplay] set,
/// in which case finishing simply closes it instead of re-marking it seen.
class OnboardingScreen extends ConsumerStatefulWidget {
  final bool isReplay;

  const OnboardingScreen({super.key, this.isReplay = false});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _pageCount = 5;

  final _controller = PageController();
  int _page = 0;

  bool get _isLast => _page == _pageCount - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (widget.isReplay) {
      if (mounted) context.pop();
      return;
    }
    await OnboardingStorage.markCompleted();
    if (mounted) context.go('/today');
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isLast ? 0 : 1,
                  child: TextButton(
                    onPressed: _isLast ? null : _finish,
                    child: Text(widget.isReplay ? 'Close' : 'Skip'),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (index) => setState(() => _page = index),
                children: [
                  _OnboardingPage(
                    illustration: const _HeroBadge(icon: Icons.check_rounded, showStreakFlame: true),
                    title: 'Build habits that stick',
                    body: 'Track what you do every day, see your consistency at a glance, '
                        'and keep your streaks alive. Free, private, and stored on your '
                        'device — no accounts, no paywall.',
                  ),
                  _OnboardingPage(
                    illustration: const _HeroBadge(icon: Icons.swap_horiz_rounded),
                    title: 'Build it, or quit it',
                    body: 'Every habit is one of two kinds.',
                    extra: const _BuildVsQuitCards(),
                  ),
                  _OnboardingPage(
                    illustration: const _SampleHeatmap(),
                    title: 'See your consistency',
                    body: 'Each habit gets a heatmap of its history, a streak counter, and a '
                        'full-year view. Tap any habit to dive in.',
                  ),
                  _OnboardingPage(
                    illustration: const _HeroBadge(icon: Icons.bolt_rounded),
                    title: 'Made to be quick',
                    body: 'A few things worth knowing:',
                    extra: const _TipsList(),
                  ),
                  _OnboardingPage(
                    illustration: const _HeroBadge(icon: Icons.palette_outlined),
                    title: 'Make it yours',
                    body: 'Pick a look. You can change this anytime in Settings → Theme.',
                    extra: const _ThemePicker(),
                  ),
                ],
              ),
            ),
            _PageDots(count: _pageCount, current: _page),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(
                    _isLast ? (widget.isReplay ? 'Done' : 'Get started') : 'Next',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Shared page layout. Scrollable (with content centered when it fits) so a
/// small screen or large system font can never overflow.
class _OnboardingPage extends StatelessWidget {
  final Widget illustration;
  final String title;
  final String body;
  final Widget? extra;

  const _OnboardingPage({
    required this.illustration,
    required this.title,
    required this.body,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight > 24 ? constraints.maxHeight - 24 : 0.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                illustration,
                const SizedBox(height: 32),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                if (extra != null) ...[
                  const SizedBox(height: 24),
                  extra!,
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Big rounded badge used as the page-1/2/4/5 illustration. Optionally shows
/// a small streak flame in the tertiary color, matching how streaks are
/// styled elsewhere in the app.
class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final bool showStreakFlame;

  const _HeroBadge({required this.icon, this.showStreakFlame = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(36),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 60, color: scheme.primary),
          ),
          if (showStreakFlame)
            Positioned(
              right: -8,
              bottom: -8,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Icon(Icons.local_fire_department, color: scheme.tertiary, size: 24),
              ),
            ),
        ],
      ),
    );
  }
}

class _BuildVsQuitCards extends StatelessWidget {
  const _BuildVsQuitCards();

  @override
  Widget build(BuildContext context) {
    return const IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _TypeCard(
              icon: Icons.add_task_rounded,
              title: 'Build',
              text: 'Start something new. Mark each day you do it.',
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _TypeCard(
              icon: Icons.smoke_free_rounded,
              title: 'Quit',
              text: 'Stop something. Days count as clean — only mark the ones you slip.',
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _TypeCard({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 22),
          ),
          const SizedBox(height: 12),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// A small static heatmap that gets denser toward the right, so the page
/// shows what "growing consistency" looks like using the app's own style.
class _SampleHeatmap extends StatelessWidget {
  const _SampleHeatmap();

  static const _rows = 5;
  static const _cols = 14;

  bool _filled(int row, int col) {
    // Deterministic pseudo-pattern, with the fill threshold rising by column.
    return ((row * 7 + col * 13) % 10) < (2 + col ~/ 2);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int r = 0; r < _rows; r++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int c = 0; c < _cols; c++)
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      color: _filled(r, c)
                          ? scheme.primary
                          : scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TipsList extends StatelessWidget {
  const _TipsList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _TipRow(
          icon: Icons.touch_app_outlined,
          text: 'Tap the check on a habit card to log today.',
        ),
        _TipRow(
          icon: Icons.edit_calendar_outlined,
          text: 'Missed a day? Open the habit and tap it on the calendar — '
              'you can go back up to $editableWindowDays days.',
        ),
        _TipRow(
          icon: Icons.sticky_note_2_outlined,
          text: 'Press and hold a calendar day to add a note.',
        ),
        _TipRow(
          icon: Icons.swap_vert_rounded,
          text: 'Press and hold a habit for options. In the Habits tab\'s list view, '
              'drag the handle to reorder.',
        ),
      ],
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TipRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Live theme chooser — picking one re-themes the whole app immediately
/// (including this screen), using the same provider Settings > Theme uses.
class _ThemePicker extends ConsumerWidget {
  const _ThemePicker();

  static const _swatches = {
    AppThemePalette.defaultTheme: [
      AppColors.teal,
      AppColors.coral,
      AppColors.paper,
      AppColors.night,
    ],
    AppThemePalette.luxEmerald: [
      LuxColors.emeraldLight,
      LuxColors.amberBronze,
      LuxColors.sageContainer,
      LuxColors.deepObsidian,
    ],
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(themeSettingsProvider).palette;

    return Column(
      children: [
        for (final palette in AppThemePalette.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ThemeChoiceCard(
              palette: palette,
              swatches: _swatches[palette] ?? const [],
              isSelected: palette == selected,
              onTap: () => ref.read(themeSettingsProvider.notifier).setPalette(palette),
            ),
          ),
      ],
    );
  }
}

class _ThemeChoiceCard extends StatelessWidget {
  final AppThemePalette palette;
  final List<Color> swatches;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeChoiceCard({
    required this.palette,
    required this.swatches,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? scheme.secondaryContainer : scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? scheme.primary : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(palette.label, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    palette.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final color in swatches)
                        Container(
                          width: 22,
                          height: 22,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.dividerColor),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int current;

  const _PageDots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == current ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == current
                  ? scheme.primary
                  : scheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}