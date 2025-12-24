class Validators {
  static String? requiredText(
    String? value, {
    String message = 'This field is required',
  }) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  /// Returns `null` if empty (treat as optional) or valid email.
  static String? optionalEmail(
    String? value, {
    String message = 'Please enter a valid email',
  }) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(v)) return message;
    return null;
  }
}
