class SignupRequestEntity {
  final String fullName;
  final String username;
  final String email;
  final String phone;
  final String password;

  SignupRequestEntity({
    required this.fullName,
    required this.username,
    required this.email,
    required this.phone,
    required this.password,
  });
}