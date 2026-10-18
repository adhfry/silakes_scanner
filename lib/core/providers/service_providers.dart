import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/config_service.dart';
import '../../services/silakes_api_service.dart';
import '../../services/gemini_service.dart';
import '../../services/firebase_service.dart';
import '../../services/local_cache_service.dart';
import '../../services/tour_guide_service.dart';

/// Provider untuk ConfigService
final configServiceProvider = Provider<ConfigService>((ref) {
  return ConfigService();
});

/// Provider untuk SilakesApiService
final silakesApiServiceProvider = Provider<SilakesApiService>((ref) {
  return SilakesApiService();
});

/// Provider untuk GeminiService
final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

/// Provider untuk FirebaseService
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

/// Provider untuk LocalCacheService
final localCacheServiceProvider = Provider<LocalCacheService>((ref) {
  return LocalCacheService();
});

/// Provider untuk TourGuideService
final tourGuideServiceProvider = Provider<TourGuideService>((ref) {
  return TourGuideService();
});
