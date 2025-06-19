import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

/// Service for encrypting and decrypting data
class EncryptionService {
  static const String _defaultKey = 'tamimah_storage_default_key_2024';
  static late String _encryptionKey;
  static late Encrypter _encrypter;
  static late IV _iv;
  static bool _initialized = false;

  /// Initialize the encryption service
  static void initialize({String? encryptionKey}) {
    if (_initialized) return;

    _encryptionKey = encryptionKey ?? _defaultKey;

    // Generate a consistent IV from the key
    final keyBytes = utf8.encode(_encryptionKey);
    final hash = sha256.convert(keyBytes);
    final ivBytes = Uint8List.fromList(hash.bytes.take(16).toList());
    _iv = IV(ivBytes);

    // Create encrypter with AES
    final key = Key.fromLength(32); // AES-256 requires 32 bytes
    _encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    _initialized = true;
  }

  /// Encrypt a string value
  static String encryptString(String value) {
    _ensureInitialized();
    final encrypted = _encrypter.encrypt(value, iv: _iv);
    return encrypted.base64;
  }

  /// Decrypt a string value
  static String decryptString(String encryptedValue) {
    _ensureInitialized();
    final encrypted = Encrypted.fromBase64(encryptedValue);
    return _encrypter.decrypt(encrypted, iv: _iv);
  }

  /// Encrypt a map/object
  static String encryptObject(Map<String, dynamic> object) {
    final jsonString = jsonEncode(object);
    return encryptString(jsonString);
  }

  /// Decrypt a map/object
  static Map<String, dynamic> decryptObject(String encryptedValue) {
    final jsonString = decryptString(encryptedValue);
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Encrypt a list
  static String encryptList(List<dynamic> list) {
    final jsonString = jsonEncode(list);
    return encryptString(jsonString);
  }

  /// Decrypt a list
  static List<dynamic> decryptList(String encryptedValue) {
    final jsonString = decryptString(encryptedValue);
    return jsonDecode(jsonString) as List<dynamic>;
  }

  /// Generate a random encryption key
  static String generateRandomKey({int length = 32}) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  /// Hash a string using SHA-256
  static String hashString(String value) {
    final bytes = utf8.encode(value);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify if a string matches its hash
  static bool verifyHash(String value, String hash) {
    return hashString(value) == hash;
  }

  /// Generate a secure random string
  static String generateSecureString({int length = 16}) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  /// Check if a string is encrypted (basic check)
  static bool isEncrypted(String value) {
    try {
      // Try to decode as base64 and decrypt
      final encrypted = Encrypted.fromBase64(value);
      return encrypted.bytes.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get encryption info
  static Map<String, dynamic> getEncryptionInfo() {
    _ensureInitialized();
    return {
      'algorithm': 'AES-256-CBC',
      'keyLength': 32,
      'ivLength': 16,
      'initialized': _initialized,
    };
  }

  static void _ensureInitialized() {
    if (!_initialized) {
      initialize();
    }
  }

  /// Dispose the encryption service
  static void dispose() {
    _initialized = false;
  }
}
