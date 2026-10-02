import 'dart:io';

class StorageService {
  Future<String> uploadImage(File file, String userId, String todoId) async {
    return file.path;
  }

  Future<void> deleteImage(String imageUrl) async {
    return;
  }
}

