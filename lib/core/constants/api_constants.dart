import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // Read the environment toggle from .env
  static bool get isProduction => dotenv.env['IS_PRODUCTION'] == 'true';

  // Read URLs from .env, providing fallbacks just in case
  static String get _railwayUrl => dotenv.env['RAILWAY_URL'] ?? '';
  static String get _localIp => dotenv.env['LOCAL_IP'] ?? '';

  static String get pythonApiBaseUrl {
    if (isProduction) {
      return _railwayUrl;
    } else {
      // Localhost routing logic
      if (kIsWeb) return 'http://127.0.0.1:8000/api';

      // If testing on a real Android phone, it MUST use the Mac's IP
      if (Platform.isAndroid) return _localIp;

      // If testing on iOS Simulator, 127.0.0.1 works fine
      if (Platform.isIOS) return 'http://127.0.0.1:8000/api';

      return 'http://127.0.0.1:8000/api';
    }
  }
}