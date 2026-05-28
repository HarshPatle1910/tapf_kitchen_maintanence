import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================================
// APP UPDATE WRAPPER & LOGIC
// ============================================================================
class AppUpdateWrapper extends StatefulWidget {
  final Widget child;
  const AppUpdateWrapper({super.key, required this.child});

  @override
  State<AppUpdateWrapper> createState() => _AppUpdateWrapperState();
}

class _AppUpdateWrapperState extends State<AppUpdateWrapper> {
  bool _isLoading = true;
  bool _needsUpdate = false;
  Map<String, dynamic>? _updateData;

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
      final platformStr = Platform.isAndroid ? 'android' : 'ios';

      debugPrint("--- UPDATE CHECK ---");
      debugPrint("Current Installed Build: $currentBuildNumber");

      final response = await Supabase.instance.client
          .from('app_versions')
          .select()
          .eq('platform', platformStr)
          .maybeSingle();

      if (response != null) {
        final latestBuildNumber = response['latest_version_code'] as int;
        final isMandatory = response['is_mandatory'] as bool;

        if (latestBuildNumber > currentBuildNumber && isMandatory) {
          debugPrint("Result: UPDATE REQUIRED!");
          _updateData = response;
          _needsUpdate = true;
        }
      }
    } catch (e) {
      debugPrint("Update check failed: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF26538D),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_needsUpdate && _updateData != null) {
      return ForceUpdateScreen(updateData: _updateData!);
    }

    return widget.child;
  }
}

// ============================================================================
// FORCE UPDATE UI
// ============================================================================
class ForceUpdateScreen extends StatelessWidget {
  final Map<String, dynamic> updateData;

  const ForceUpdateScreen({super.key, required this.updateData});

  Future<void> _launchDownloadUrl(BuildContext context) async {
    final urlString = updateData['download_url'];
    if (urlString == null || urlString.isEmpty) return;

    final url = Uri.parse(urlString);

    try {
      // FIX: Bypassing canLaunchUrl and forcing the external browser to open.
      // The browser natively handles the downloading of the APK.
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open download link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final versionName = updateData['latest_version_name'];
    final releaseNotes = updateData['release_notes'] ?? 'Please update the app to continue.';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF26538D).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.system_update_rounded, size: 80, color: Color(0xFF26538D)),
              ),
              const SizedBox(height: 32),
              Text(
                "Update Required",
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF26538D)),
              ),
              const SizedBox(height: 12),
              Text(
                "Version $versionName is now available.",
                style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("What's New:", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 8),
                    Text(releaseNotes, style: GoogleFonts.inter(height: 1.5, color: Colors.black54)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => _launchDownloadUrl(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF26538D),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text("Download & Install", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Text(
                "After downloading, tap the APK file in your notifications to install.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
              )
            ],
          ),
        ),
      ),
    );
  }
}