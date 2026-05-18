import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  // =========================================================
  // 🎛️ ENVIRONMENT TOGGLE
  // Set to TRUE to use Railway. Set to FALSE to use your Mac.
  // =========================================================
  static const bool isProduction = false;

  // ☁️ LIVE: Your Railway Domain (Make sure there is no trailing slash)
  static const String _railwayUrl = 'https://tapfkitchenmaintanancebackend-production.up.railway.app/api';

  // 💻 LOCAL: Your Mac's Wi-Fi IP Address (Required for testing on a real phone)
  static const String _localIp = 'http://192.168.2.143:8000/api';


  // =========================================================
  // SMART URL ROUTER
  // Every file in your app will call this getter.
  // =========================================================
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