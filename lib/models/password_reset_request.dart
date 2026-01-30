/// Model for password reset request
class PasswordResetRequest {
  final String oobCode;
  final String newPassword;

  PasswordResetRequest({
    required this.oobCode,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'oobCode': oobCode,
      'newPassword': newPassword,
    };
  }
}

/// Model for password reset response
class PasswordResetResponse {
  final bool success;
  final String? message;
  final String? email;

  PasswordResetResponse({
    required this.success,
    this.message,
    this.email,
  });

  factory PasswordResetResponse.fromJson(Map<String, dynamic> json) {
    return PasswordResetResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      email: json['email'] as String?,
    );
  }
}
