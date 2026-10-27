import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PasswordHasher {
  static String generateSalt([int len = 16]) {
    final r = Random.secure();
    return base64Url.encode(List<int>.generate(len, (_) => r.nextInt(256)));
  }

  static String hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt$password')).toString();
}