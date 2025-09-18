import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class StorageRepository {
  StorageRepository(this._client);

  final SupabaseClient _client;

  Future<String> uploadBusinessPhoto({
    required String businessId,
    required Uint8List bytes,
    String fileName = 'cover.jpg',
    String contentType = 'image/jpeg',
  }) async {
    final path = '$businessId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final storage = _client.storage.from('business_photos');

    try {
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: contentType, upsert: true),
      );
      return storage.getPublicUrl(path);
    } on StorageException catch (error) {
      throw Exception('İşletme fotoğrafı yüklenemedi: ${error.message}');
    }
  }

  Future<String> uploadServicePhoto({
    required String businessId,
    required String serviceId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    final path = '$businessId/$serviceId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storage = _client.storage.from('service_photos');

    try {
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: contentType, upsert: true),
      );
      return storage.getPublicUrl(path);
    } on StorageException catch (error) {
      throw Exception('Hizmet fotoğrafı yüklenemedi: ${error.message}');
    }
  }

  Future<String> uploadUserAvatar({
    required String userId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    final path = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storage = _client.storage.from('user_avatars');

    try {
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: contentType, upsert: true),
      );
      final signedUrl = await storage.createSignedUrl(path, 60 * 60 * 24); // 24 saat
      return signedUrl;
    } on StorageException catch (error) {
      throw Exception('Avatar yüklenemedi: ${error.message}');
    }
  }
}
