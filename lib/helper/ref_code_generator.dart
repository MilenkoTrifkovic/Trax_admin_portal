import 'dart:math';

/// Generates a unique reference code for sales people
/// Format: First 3 letters of name (uppercase) + 3 random digits
/// Example: "JOH123" for "John Smith"
class RefCodeGenerator {
  static final Random _random = Random();

  /// Generates a reference code based on the person's name
  /// Returns a string like "JOH123"
  static String generate(String name) {
    // Get first 3 letters from name (remove spaces and take first 3 chars)
    final cleanName = name.replaceAll(RegExp(r'[^a-zA-Z]'), '').toUpperCase();
    final prefix = cleanName.length >= 3 
        ? cleanName.substring(0, 3)
        : cleanName.padRight(3, 'X'); // Pad with X if name is too short

    // Generate 3 random digits
    final digits = _generateRandomDigits(3);

    return '$prefix$digits';
  }

  /// Generates N random digits as a string
  static String _generateRandomDigits(int count) {
    final buffer = StringBuffer();
    for (int i = 0; i < count; i++) {
      buffer.write(_random.nextInt(10));
    }
    return buffer.toString();
  }

  /// Regenerates just the digits part while keeping the prefix
  /// Used when a code collision is detected
  static String regenerateDigits(String existingCode) {
    if (existingCode.length < 3) {
      return generate('XXX'); // Fallback if code is malformed
    }

    final prefix = existingCode.substring(0, 3);
    final newDigits = _generateRandomDigits(3);
    return '$prefix$newDigits';
  }

  /// Validates if a reference code has the correct format
  static bool isValidFormat(String code) {
    final regex = RegExp(r'^[A-Z]{3}\d{3}$');
    return regex.hasMatch(code);
  }
}
