import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ordering_food_system/app/router.dart';
import 'package:ordering_food_system/core/theme/app_colors.dart';
import 'package:ordering_food_system/core/theme/app_spacing.dart';
import 'package:ordering_food_system/core/theme/app_text_styles.dart';
import 'package:ordering_food_system/core/widgets/food_ninja_background.dart';
import 'package:ordering_food_system/core/widgets/primary_button.dart';
import 'package:ordering_food_system/features/onboarding/presentation/viewmodels/onboarding_view_model.dart';

class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  final PageController _pageController = PageController();

  final List<Map<String, dynamic>> _pages = const [
    {
      'title': 'Find your Comfort\nFood here',
      'description':
          'Here You Can find a chef or dish for every taste and color. Enjoy!',
      'icon': Icons.fastfood_rounded,
      'accentColor': AppColors.primarySoft,
      'iconColor': AppColors.primarySolid,
    },
    {
      'title': 'Food Ninja is Where\nYour Comfort Food Lives',
      'description': 'Enjoy a fast and smooth food delivery directly to your doorstep with Cash on Delivery.',
      'icon': Icons.delivery_dining_rounded,
      'accentColor': AppColors.warningSurface,
      'iconColor': AppColors.foodAccentDark,
    },
    {
      'title': 'Track & Receive\nYour Meals Easily',
      'description': 'Stay notified at each step from preparation to arrival. Order now and satisfy your cravings!',
      'icon': Icons.notifications_active_rounded,
      'accentColor': AppColors.successSoft,
      'iconColor': AppColors.success,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleFinish() async {
    await ref.read(onboardingViewModelProvider.notifier).completeOnboarding();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingViewModelProvider);
    final isLastPage = state.currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FoodNinjaBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.p8),

                // Top bar: Skip button in Food Ninja green
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _handleFinish,
                    child: Text(
                      'Skip',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.primarySolid,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // PageView with Food Ninja Illustration Style
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      ref
                          .read(onboardingViewModelProvider.notifier)
                          .setPage(index);
                    },
                    itemBuilder: (context, index) {
                      final item = _pages[index];
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Food Ninja Character / Illustration Container
                          Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              color: item['accentColor'] as Color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (item['iconColor'] as Color)
                                      .withValues(alpha: 0.2),
                                  blurRadius: 40,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                item['icon'] as IconData,
                                size: 100,
                                color: item['iconColor'] as Color,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.p40),

                          Text(
                            item['title'] as String,
                            style: AppTextStyles.headlineLarge.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.p16),

                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.p16,
                            ),
                            child: Text(
                              item['description'] as String,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Food Ninja Dots Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: state.currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: state.currentPage == index
                            ? AppColors.primarySolid
                            : AppColors.borderLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.p32),

                // Food Ninja CTA Next Button (157px minimum width, centered)
                Center(
                  child: PrimaryButton(
                    width: 160,
                    text: isLastPage ? 'Get Started' : 'Next',
                    onPressed: () {
                      if (isLastPage) {
                        _handleFinish();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.p32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
