abstract final class Validators {
  static String? required(String? value, {String message = '此项不能为空'}) => value == null || value.trim().isEmpty ? message : null;
  static String? phone(String? value) => value != null && RegExp(r'^1\d{10}$').hasMatch(value) ? null : '请输入有效的手机号';
  static String? verificationCode(String? value) => value != null && RegExp(r'^\d{6}$').hasMatch(value) ? null : '请输入6位验证码';
  static String? password(String? value) => value != null && value.length >= 8 ? null : '密码至少需要8位';
}
