// resources/storage_methods.dart
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // إضافة صورة إلى Firebase Storage
  Future<String> uploadImageToStorage(
      String childName, Uint8List file, bool isPost) async {
    try {
      // إنشاء reference داخل الـ bucket الجديد (بتاخد من google-services.json الجديد)
      Reference ref =
          _storage.ref().child(childName).child(_auth.currentUser!.uid);

      if (isPost) {
        String id = const Uuid().v1();
        ref = ref.child(id);
      }

      // رفع الصورة
      UploadTask uploadTask = ref.putData(file);
      TaskSnapshot snapshot = await uploadTask;

      // جلب الرابط النهائي
      String downloadUrl = await snapshot.ref.getDownloadURL();

      if (downloadUrl.startsWith("https://")) {
        print("✅ Uploaded image URL: $downloadUrl");
      } else {
        print("⚠️ Warning: URL might be invalid: $downloadUrl");
      }

      return downloadUrl;
    } catch (e) {
      print("❌ Error uploading image: ${e.toString()}");
      rethrow;
    }
  }
}
