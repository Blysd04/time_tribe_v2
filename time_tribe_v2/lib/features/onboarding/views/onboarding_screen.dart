import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/views/widgets/app_logo.dart';
import '../../home/views/home_screen.dart';
import '../onboarding_service.dart';

/// Màn hình chào mừng người mới đăng ký: vài trang giới thiệu lợi ích của app,
/// trang cuối hỏi người dùng đã biết dùng chưa để quyết định có chạy hướng dẫn hay không.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  bool _leaving = false;

  /// 4 trang giới thiệu + 1 trang lựa chọn.
  static const _introCount = 4;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) => _controller.animateToPage(
    page,
    duration: const Duration(milliseconds: 380),
    curve: Curves.easeOutCubic,
  );

  /// Chọn xong ở trang cuối: lưu lại rồi vào trang chủ (có hoặc không có hướng dẫn).
  Future<void> _finish({required bool wantsTour}) async {
    if (_leaving) return;
    _leaving = true;
    await Onboarding.complete(wantsTour: wantsTour);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const HomeScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final onChoice = _page == _introCount;

    final pages = <Widget>[
      _IntroPage(
        hero: const AppLogo(height: 130),
        title: l.onbWelcomeTitle,
        body: l.onbWelcomeBody,
      ),
      _IntroPage(
        hero: const _IconHero(
          icon: Icons.view_timeline_outlined,
          color: AppColors.primary,
          badges: [Icons.palette_outlined, Icons.alarm_outlined],
        ),
        title: l.onbPersonalTitle,
        body: l.onbPersonalBody,
      ),
      _IntroPage(
        hero: const _IconHero(
          icon: Icons.groups_rounded,
          color: AppColors.success,
          badges: [Icons.public, Icons.event_available_outlined],
        ),
        title: l.onbTribeTitle,
        body: l.onbTribeBody,
      ),
      _IntroPage(
        hero: const _IconHero(
          icon: Icons.notifications_active_outlined,
          color: AppColors.warning,
          badges: [Icons.check_circle_outline, Icons.dashboard_customize_outlined],
        ),
        title: l.onbNotiTitle,
        body: l.onbNotiBody,
      ),
      _ChoicePage(
        onExpert: () => _finish(wantsTour: false),
        onNewbie: () => _finish(wantsTour: true),
      ),
    ];

    return PopScope(
      // Nút Back của máy: lùi trang, không thoát khỏi phần chào mừng
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _page > 0) _goTo(_page - 1);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 52,
                child: Row(
                  children: [
                    if (_page > 0)
                      IconButton(
                        tooltip: l.onbBack,
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                        onPressed: () => _goTo(_page - 1),
                      ),
                    const Spacer(),
                    if (!onChoice)
                      TextButton(
                        onPressed: () => _goTo(_introCount),
                        child: Text(
                          l.onbSkip,
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: pages,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: onChoice
                    ? const SizedBox(height: 24)
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        child: Column(
                          children: [
                            _Dots(count: _introCount + 1, index: _page),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () => _goTo(_page + 1),
                                child: Text(
                                  l.onbNext,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Một trang giới thiệu: hình minh hoạ, tiêu đề, mô tả.
class _IntroPage extends StatelessWidget {
  final Widget hero;
  final String title;
  final String body;

  const _IntroPage({
    required this.hero,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              hero,
              const SizedBox(height: 40),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                body,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: cs.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hình minh hoạ: vòng tròn màu nhạt với icon lớn ở giữa và hai icon nhỏ bay quanh.
class _IconHero extends StatelessWidget {
  final IconData icon;
  final Color color;
  final List<IconData> badges;

  const _IconHero({
    required this.icon,
    required this.color,
    required this.badges,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    Widget badge(IconData i) => Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(i, color: color, size: 26),
    );

    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: 0.22),
                  color.withValues(alpha: 0.06),
                ],
              ),
            ),
          ),
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 60),
          ),
          if (badges.isNotEmpty)
            Positioned(top: 10, right: 6, child: badge(badges[0])),
          if (badges.length > 1)
            Positioned(bottom: 14, left: 4, child: badge(badges[1])),
        ],
      ),
    );
  }
}

/// Chấm chỉ trang hiện tại.
class _Dots extends StatelessWidget {
  final int count;
  final int index;
  const _Dots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index
                  ? AppColors.primary
                  : cs.onSurface.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

/// Trang cuối: "Tôi đã biết sử dụng" hoặc "Tôi là người mới".
class _ChoicePage extends StatelessWidget {
  final VoidCallback onExpert;
  final VoidCallback onNewbie;

  const _ChoicePage({required this.onExpert, required this.onNewbie});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _IconHero(
                icon: Icons.waving_hand_outlined,
                color: AppColors.primary,
                badges: [],
              ),
              const SizedBox(height: 28),
              Text(
                l.onbChoiceTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l.onbChoiceSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 32),
              _ChoiceCard(
                icon: Icons.school_outlined,
                color: AppColors.primary,
                title: l.onbChoiceNewbie,
                subtitle: l.onbChoiceNewbieDesc,
                highlighted: true,
                onTap: onNewbie,
              ),
              const SizedBox(height: 14),
              _ChoiceCard(
                icon: Icons.rocket_launch_outlined,
                color: AppColors.success,
                title: l.onbChoiceExpert,
                subtitle: l.onbChoiceExpertDesc,
                onTap: onExpert,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool highlighted;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: highlighted ? color.withValues(alpha: 0.08) : cs.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: highlighted ? color : cs.onSurface.withValues(alpha: 0.12),
              width: highlighted ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurface.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
