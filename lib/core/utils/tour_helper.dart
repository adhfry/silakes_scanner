import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../theme/app_theme.dart';

/// Helper untuk membuat tour targets
class TourHelper {
  /// Create a tour target dengan custom content
  static TargetFocus createTarget({
    required GlobalKey key,
    required String title,
    required String description,
    ContentAlign align = ContentAlign.bottom,
    ShapeLightFocus shape = ShapeLightFocus.RRect,
  }) {
    return TargetFocus(
      identify: key.toString(),
      keyTarget: key,
      alignSkip: Alignment.topRight,
      shape: shape,
      contents: [
        TargetContent(
          align: align,
          padding: const EdgeInsets.all(20),
          builder: (context, controller) {
            return _buildContent(
              context: context,
              title: title,
              description: description,
              controller: controller,
            );
          },
        ),
      ],
    );
  }

  /// Build content widget untuk tour
  static Widget _buildContent({
    required BuildContext context,
    required String title,
    required String description,
    required TutorialCoachMarkController controller,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon & Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Description
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          
          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Skip Button
              TextButton(
                onPressed: () => controller.skip(),
                child: const Text(
                  'Lewati Semua',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              // Next/Paham Button
              ElevatedButton.icon(
                onPressed: () => controller.next(),
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text('Paham'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Show coach mark dengan custom styling
  static void showTour({
    required BuildContext context,
    required List<TargetFocus> targets,
    required VoidCallback onFinish,
    required VoidCallback onSkip,
  }) {
    TutorialCoachMark(
      targets: targets,
      colorShadow: AppTheme.primaryColor,
      opacityShadow: 0.8,
      paddingFocus: 10,
      onFinish: () => onFinish(),
      onSkip: () {
        onSkip();
        return true;
      },
    ).show(context: context);
  }
}
