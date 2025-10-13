import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../controllers/auth_controller.dart';

class AuthLandingView extends StatefulWidget {
  const AuthLandingView({super.key});

  @override
  State<AuthLandingView> createState() => _AuthLandingViewState();
}

class _AuthLandingViewState extends State<AuthLandingView> {
  late final PageController _pageController;
  int _page = 0;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Auto-scroll the tutorial carousel
    _autoTimer = Timer.periodic(const Duration(seconds: 4), (t) {
      if (!mounted) return;
      final int next = (_page + 1) % 3;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Text(
                'Connect with\nothers musicians',
                textAlign: TextAlign.center,
                style: textTheme.headlineLarge,
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 320,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _page = i),
                  physics: const BouncingScrollPhysics(),
                  children: const [
                    _HeroDisc(asset: 'assets/icons/musicians-disk-img.png'),
                    _HeroDisc(asset: 'assets/icons/musicians-disk-img-1.png'),
                    _HeroDisc(asset: 'assets/icons/musicians-disk-img-2.png'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Dots(isDark: isDark, activeIndex: _page, total: 3),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Get.toNamed(AppRoutes.signUp),
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/icons/email-ic.png', width: 22, height: 22, color: isDark ? Colors.black : Colors.white),
                      const SizedBox(width: 12),
                      const Text('Continue with email'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('OR SIGN IN WITH', style: textTheme.labelLarge?.copyWith(color: colors.onSurface.withOpacity(0.8))),
              const SizedBox(height: 18),
              _SocialRow(controller: Get.find<AuthController>()),
              const Spacer(),
              _BottomSignIn(textTheme: textTheme, colors: colors),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroDisc extends StatelessWidget {
  final String asset;
  const _HeroDisc({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 280,
            height: 280,
            decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 24)]),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(asset, fit: BoxFit.cover),
          ),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.5),
                ],
              ),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final bool isDark;
  final int activeIndex;
  final int total;
  const _Dots({required this.isDark, required this.activeIndex, required this.total});

  @override
  Widget build(BuildContext context) {
    final Color active = isDark ? Colors.white : Colors.black;
    final Color inactive = Theme.of(context).colorScheme.onSurface.withOpacity(0.35);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final bool isActive = i == activeIndex;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: isActive ? 10 : 8,
          height: isActive ? 10 : 8,
          decoration: BoxDecoration(color: isActive ? active : inactive, shape: BoxShape.circle),
        );
      }),
    );
  }

  Widget _dot(Color color) => Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _SocialRow extends StatelessWidget {
  final AuthController controller;
  const _SocialRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialButton(asset: 'assets/icons/facebook.png', onTap: controller.facebookSignIn, colors: colors),
        const SizedBox(width: 16),
        _SocialButton(asset: 'assets/icons/apple.png', onTap: controller.appleSignIn, colors: colors),
        const SizedBox(width: 16),
        _SocialButton(asset: 'assets/icons/google.png', onTap: controller.googleSignIn, colors: colors),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String asset;
  final VoidCallback onTap;
  final ColorScheme colors;
  const _SocialButton({required this.asset, required this.onTap, required this.colors});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.onSurface.withOpacity(0.8), width: 1.2),
        ),
        child: Center(child: Image.asset(asset, width: 20, height: 20, color: colors.onSurface)),
      ),
    );
  }
}

class _BottomSignIn extends StatelessWidget {
  final TextTheme textTheme;
  final ColorScheme colors;
  const _BottomSignIn({required this.textTheme, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Already have an account? ', style: textTheme.bodyLarge?.copyWith(color: colors.onBackground.withOpacity(0.8))),
        GestureDetector(
          onTap: () => Get.toNamed(AppRoutes.signIn),
          child: Text('Sign In', style: textTheme.titleMedium?.copyWith(color: colors.onBackground)),
        ),
      ],
    );
  }
}



