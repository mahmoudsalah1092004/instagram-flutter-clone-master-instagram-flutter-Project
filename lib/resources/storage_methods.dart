import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class StorageMethods {
  
  // 🟢 استبدل هذه القيم ببياناتك من موقع Cloudinary
  final String cloudName = "dpkwxusop"; 
  final String uploadPreset = "instagram_preset"; 

  // دالة رفع الصور لـ Cloudinary
  Future<String> uploadImageToStorage(String childName, Uint8List file, bool isPost) async {
    try {
      // 1. تحديد عنوان الـ API الخاص بـ Cloudinary
      var uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

      // 2. تجهيز الطلب (Request)
      var request = http.MultipartRequest("POST", uri);

      // 3. تحويل ملف الصورة لملف يقبله السيرفر
      var multipartFile = http.MultipartFile.fromBytes(
        'file', // اسم الحقل المطلوب في Cloudinary
        file,
        filename: "${const Uuid().v1()}.jpg", // اسم عشوائي للصورة
      );

      // 4. إضافة الصورة والبيانات اللازمة للطلب
      request.files.add(multipartFile);
      request.fields['upload_preset'] = uploadPreset; // الـ Preset الذي أنشأناه
      request.fields['resource_type'] = 'image';

      // 5. إرسال الطلب وانتظار الرد
      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      // 6. التحقق من النجاح واستخراج الرابط
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(responseData.body);
        return jsonData['secure_url']; // ✅ هذا هو رابط الصورة الجاهز!
      } else {
        throw "Failed to upload image: ${response.statusCode}";
      }
    } catch (e) {
      throw e.toString();
    }
  }
}