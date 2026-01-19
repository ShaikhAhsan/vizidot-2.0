import 'package:encrypt/encrypt.dart' as ENC;

final key = ENC.Key.fromUtf8('put32charactershereeeeeeeeeeeee!'); //32 chars
final iv = ENC.IV.fromUtf8('put16characters!'); //16 chars

//encrypt
String encryptMyData(String text) {
  final e = ENC.Encrypter(ENC.AES(key, mode: ENC.AESMode.cbc));
  final encrypted_data = e.encrypt(text, iv: iv);
  return encrypted_data.base64;
}

//decrypt
String decryptMyData(String text) {
  final e = ENC.Encrypter(ENC.AES(key, mode: ENC.AESMode.cbc));
  final decrypted_data = e.decrypt(ENC.Encrypted.fromBase64(text), iv: iv);
  return decrypted_data;
}

String getFileName(String url) {
  // Extract filename from URL path
  final uri = Uri.parse(url);
  final pathSegments = uri.pathSegments;
  if (pathSegments.isEmpty) return '';
  
  final filename = pathSegments.last;
  // Remove URL encoding and path separators
  return filename.replaceAll("uploads%2F", "").replaceAll("uploads/", "");
}
