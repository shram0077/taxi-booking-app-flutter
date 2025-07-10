// ignore_for_file: avoid_print, duplicate_ignore

import 'package:encrypt/encrypt.dart';

class MyEncriptionDecription {
  //For AES Encryption/Decryption

  static encryptWithAESKey(String value) {
    final key = Key.fromUtf8("1245714587458888"); //hardcode
    final iv = IV.fromUtf8("e16ce888a20dadb8"); //hardcode

    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(value, iv: iv);

    return encrypted.base64;
  }

  static String decryptWithAESKey(String encrypted) {
    try {
      final key = Key.fromUtf8(
          "1245714587458888"); //hardcode combination of 16 character
      final iv = IV
          .fromUtf8("e16ce888a20dadb8"); //hardcode combination of 16 character

      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      Encrypted enBase64 = Encrypted.from64(encrypted);
      final decrypted = encrypter.decrypt(enBase64, iv: iv);
      return decrypted;
    } catch (e) {
      if (e == "") {
        print("the ERROR: $e");
      }
    }
    return encrypted;
  }
}
