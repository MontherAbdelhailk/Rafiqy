// core/helpers/app_regex.dart
class AppRegex {
  static bool isPasswordValid(String password) =>
      RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$').hasMatch(password);
  
  static bool isPhoneNumberValid(String phoneNumber) =>
      RegExp(r'^(010|011|012|015)[0-9]{8}$').hasMatch(phoneNumber);
}