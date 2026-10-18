import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/logger.dart';

/// Service untuk mengelola status tour guide
class TourGuideService {
  static const String _keyDashboardTour = 'tour_dashboard_completed';
  static const String _keyCameraTour = 'tour_camera_completed';
  static const String _keyPreviewTour = 'tour_preview_completed';
  static const String _keyFirstLaunch = 'app_first_launch';

  /// Check apakah ini first launch
  Future<bool> isFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirst = prefs.getBool(_keyFirstLaunch) ?? true;
      
      if (isFirst) {
        Logger.info('First launch detected', tag: 'TourGuide');
        await prefs.setBool(_keyFirstLaunch, false);
      }
      
      return isFirst;
    } catch (e) {
      Logger.error('Error checking first launch', tag: 'TourGuide', error: e);
      return false;
    }
  }

  /// Check apakah dashboard tour sudah selesai
  Future<bool> isDashboardTourCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyDashboardTour) ?? false;
    } catch (e) {
      Logger.error('Error checking dashboard tour', tag: 'TourGuide', error: e);
      return false;
    }
  }

  /// Tandai dashboard tour sebagai selesai
  Future<void> completeDashboardTour() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDashboardTour, true);
      Logger.info('Dashboard tour completed', tag: 'TourGuide');
    } catch (e) {
      Logger.error('Error completing dashboard tour', tag: 'TourGuide', error: e);
    }
  }

  /// Check apakah camera tour sudah selesai
  Future<bool> isCameraTourCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyCameraTour) ?? false;
    } catch (e) {
      Logger.error('Error checking camera tour', tag: 'TourGuide', error: e);
      return false;
    }
  }

  /// Tandai camera tour sebagai selesai
  Future<void> completeCameraTour() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyCameraTour, true);
      Logger.info('Camera tour completed', tag: 'TourGuide');
    } catch (e) {
      Logger.error('Error completing camera tour', tag: 'TourGuide', error: e);
    }
  }

  /// Check apakah preview tour sudah selesai
  Future<bool> isPreviewTourCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyPreviewTour) ?? false;
    } catch (e) {
      Logger.error('Error checking preview tour', tag: 'TourGuide', error: e);
      return false;
    }
  }

  /// Tandai preview tour sebagai selesai
  Future<void> completePreviewTour() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyPreviewTour, true);
      Logger.info('Preview tour completed', tag: 'TourGuide');
    } catch (e) {
      Logger.error('Error completing preview tour', tag: 'TourGuide', error: e);
    }
  }

  /// Reset semua tour (untuk testing)
  Future<void> resetAllTours() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyDashboardTour);
      await prefs.remove(_keyCameraTour);
      await prefs.remove(_keyPreviewTour);
      await prefs.setBool(_keyFirstLaunch, true);
      Logger.info('All tours reset', tag: 'TourGuide');
    } catch (e) {
      Logger.error('Error resetting tours', tag: 'TourGuide', error: e);
    }
  }

  /// Skip semua tour
  Future<void> skipAllTours() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDashboardTour, true);
      await prefs.setBool(_keyCameraTour, true);
      await prefs.setBool(_keyPreviewTour, true);
      Logger.info('All tours skipped', tag: 'TourGuide');
    } catch (e) {
      Logger.error('Error skipping tours', tag: 'TourGuide', error: e);
    }
  }
}
