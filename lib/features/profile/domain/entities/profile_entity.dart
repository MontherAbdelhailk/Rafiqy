class ProfileEntity {
  final String firstName;
  final String lastName;
  final String phone;
  final int age;
  final String status;
  final int childrenCount;
  final String bio;
  final String? profilePicture;

  ProfileEntity({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.age,
    required this.status,
    required this.childrenCount,
    required this.bio,
    this.profilePicture,
  });

  String get fullName => '$firstName $lastName';
}