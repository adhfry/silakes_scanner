import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';

/// Widget overlay untuk guide KTP di kamera
class CameraOverlayWidget extends StatelessWidget {
  const CameraOverlayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double cardWidth = size.width * 0.85;
    final double cardHeight = cardWidth / AppConfig.ktpAspectRatio;

    return Stack(
      children: [
        // Dark overlay
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.6),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              // Card cutout
              Center(
                child: Container(
                  width: cardWidth,
                  height: cardHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Card border guide
        Center(
          child: Container(
            width: cardWidth,
            height: cardHeight,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.primaryColor,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Stack(
              children: [
                // Corner indicators
                _buildCorner(
                  top: 0,
                  left: 0,
                  borderTop: true,
                  borderLeft: true,
                ),
                _buildCorner(
                  top: 0,
                  right: 0,
                  borderTop: true,
                  borderRight: true,
                ),
                _buildCorner(
                  bottom: 0,
                  left: 0,
                  borderBottom: true,
                  borderLeft: true,
                ),
                _buildCorner(
                  bottom: 0,
                  right: 0,
                  borderBottom: true,
                  borderRight: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCorner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    bool borderTop = false,
    bool borderBottom = false,
    bool borderLeft = false,
    bool borderRight = false,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: borderTop
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            bottom: borderBottom
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            left: borderLeft
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            right: borderRight
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
