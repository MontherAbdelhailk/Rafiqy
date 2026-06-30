import 'package:rafiq/features/profile/domain/entities/profile_entity.dart';

class ProfileModel extends ProfileEntity {
  ProfileModel({
    required super.firstName,
    required super.lastName,
    required super.phone,
    required super.age,
    required super.status,
    required super.childrenCount,
    required super.bio,
    super.profilePicture,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phone: json['phone_number'] ?? '',
      age: json['age'] != null ? int.parse(json['age'].toString()) : 0,
      status: json['marital_status'] ?? 'Single',
      childrenCount: json['children_count'] != null ? int.parse(json['children_count'].toString()) : 0,
      bio: json['bio'] ?? "Parenting Enthusiast",
      profilePicture: json['profile_picture'],
    );
  }
}