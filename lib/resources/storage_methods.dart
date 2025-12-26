import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class StorageMethods {
  
  final String cloudName = "dpkwxusop"; 
  final String uploadPreset = "instagram_preset"; 

  Future<String> uploadImageToStorage(String childName, Uint8List file, bool isPost) async {
    try {
      var uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

      var request = http.MultipartRequest("POST", uri);

      var multipartFile = http.MultipartFile.fromBytes(
        'file', 
        file,
        filename: "${const Uuid().v1()}.jpg", 
      );

      request.files.add(multipartFile);
      request.fields['upload_preset'] = uploadPreset; 
      request.fields['resource_type'] = 'image';

      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(responseData.body);
        return jsonData['secure_url']; 
      } else {
        throw "Failed to upload image: ${response.statusCode}";
      }
    } catch (e) {
      throw e.toString();
    }
  }
}