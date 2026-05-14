import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../datasources/supabase_client.dart';

class StorageRepository {
  static const _avatarBucket = 'avatars';
  static const _itemBucket = 'item-images';

  final _picker = ImagePicker();

  // ── Image picker helpers ───────────────────────────────────────────────────

  Future<XFile?> pickFromGallery({int quality = 85, double maxWidth = 1024}) =>
      _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: quality,
        maxWidth: maxWidth,
      );

  Future<XFile?> pickFromCamera({int quality = 85, double maxWidth = 1024}) =>
      _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: quality,
        maxWidth: maxWidth,
      );

  // ── Avatar ─────────────────────────────────────────────────────────────────

  /// Uploads [file] to `avatars/{userId}.jpg` and returns the public URL.
  Future<String> uploadAvatar(String userId, XFile file) async {
    final bytes = await file.readAsBytes();
    final path = '$userId.jpg';

    await supabase.storage.from(_avatarBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    return supabase.storage.from(_avatarBucket).getPublicUrl(path);
  }

  /// Saves the avatar URL to `profiles.avatar_url`.
  Future<void> saveAvatarUrl(String userId, String url) async {
    await supabase
        .from('profiles')
        .update({'avatar_url': url}).eq('id', userId);
  }

  /// Fetches `avatar_url` from the profiles table for [userId].
  Future<String?> getAvatarUrl(String userId) async {
    final data = await supabase
        .from('profiles')
        .select('avatar_url')
        .eq('id', userId)
        .maybeSingle();
    return data?['avatar_url'] as String?;
  }

  // ── Item images ────────────────────────────────────────────────────────────

  /// Uploads [file] to `item-images/{itemId}.jpg` and returns the public URL.
  Future<String> uploadItemImage(String itemId, XFile file) async {
    final bytes = await file.readAsBytes();
    final path = '$itemId.jpg';

    await supabase.storage.from(_itemBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    return supabase.storage.from(_itemBucket).getPublicUrl(path);
  }
}
