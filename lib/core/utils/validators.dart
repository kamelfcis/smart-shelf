class AppValidators {
  AppValidators._();

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final re = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!re.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? required(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? positiveNumber(String? value, {String label = 'Value'}) {
    if (value == null || value.isEmpty) return '$label is required';
    final n = double.tryParse(value);
    if (n == null) return '$label must be a number';
    if (n < 0) return '$label must be positive';
    return null;
  }

  static String? positiveInt(String? value, {String label = 'Value'}) {
    if (value == null || value.isEmpty) return '$label is required';
    final n = int.tryParse(value);
    if (n == null) return '$label must be a whole number';
    if (n < 0) return '$label must be positive';
    return null;
  }
}
