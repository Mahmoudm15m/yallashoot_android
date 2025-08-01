import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:convert/convert.dart';

final Key AES_KEY = Key(Uint8List.fromList(hex.decode("4e5c6d1a8b3fe8137a3b9df26a9c4de195267b8e6f6c0b4e1c3ae1d27f2b4e6f")));
final IV IV_VALUE = IV(Uint8List.fromList(hex.decode("a9c21f8d7e6b4a9db12e4f9d5c1a7b8e")));

String decodeResponse(String ciphertext) {
  final encryptedBytes = base64.decode(ciphertext);
  final encrypter = Encrypter(AES(AES_KEY, mode: AESMode.cbc));
  final decrypted = encrypter.decryptBytes(Encrypted(encryptedBytes), iv: IV_VALUE);

  int padLen = decrypted.last;
  if (padLen > 16) {
    return utf8.decode(decrypted, allowMalformed: true);
  }

  return utf8.decode(decrypted.sublist(0, decrypted.length - padLen), allowMalformed: true);
}

String generateRandomString({int length = 10}) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final rand = Random();
  return List.generate(length, (index) => chars[rand.nextInt(chars.length)]).join();
}

