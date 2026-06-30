class UserEntity {
  final String token;
  final String name;
  final String email; // 👈 إضافة final هنا عشان الكلاس يكون Immutable وصح

  UserEntity({
    required this.token, 
    required this.name, 
    required this.email,
  });
}