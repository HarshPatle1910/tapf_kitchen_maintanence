// ignore_for_file: avoid_print
// ignore_for_file: avoid_print
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path/path.dart' as p;
import 'package:mime/mime.dart';

class FirebaseMediaService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future? compressAndUpload({
    required File file,
    required String ticketId,
    required String uploadStage, // 'raised' or 'completion'
    required String mediaType,   // 'photo' or 'video'
  }) async {
    try {
      File processedFile = file;
      final String originalFileName = p.basename(file.path);

      // 1. COMPRESSION LOGIC
      if (mediaType == 'photo') {
        final targetPath = p.join(p.dirname(file.path), 'compressed_$originalFileName');
        final compressedImage = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          targetPath,
          quality: 70, // Adjust 0-100
          minWidth: 1024,
          minHeight: 1024,
        );
        if (compressedImage != null) processedFile = File(compressedImage.path);
      } else if (mediaType == 'video') {
        final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
          file.path,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
        );
        if (mediaInfo != null && mediaInfo.file != null) {
          processedFile = mediaInfo.file!;
        }
      }

      // 2. METADATA EXTRACTION
      final String fileName = p.basename(processedFile.path);
      final int fileSize = await processedFile.length();
      final String contentType = lookupMimeType(processedFile.path) ?? 'application/octet-stream';

      // 3. FIREBASE UPLOAD
      // Path: pmt_tickets///
      final String storagePath = 'pmt_tickets/$ticketId/$uploadStage/$fileName';
      final Reference ref = _storage.ref().child(storagePath);

      final UploadTask uploadTask = ref.putFile(
        processedFile,
        SettableMetadata(contentType: contentType),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Clean up video compression cache if applicable
      if (mediaType == 'video') await VideoCompress.deleteAllCache();

      // 4. RETURN DATA FOR SUPABASE
      return {
        'media_url': downloadUrl,
        'file_name': fileName,
        'file_size': fileSize,
        'content_type': contentType,
      };
    } catch (e) {
      print("Firebase Upload Error: \$e");
      return null;
    }
  }
}