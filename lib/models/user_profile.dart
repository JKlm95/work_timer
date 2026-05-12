import 'package:cloud_firestore/cloud_firestore.dart';

/// Dokument `users/{uid}/profile/main`.
class UserProfile {
  const UserProfile({
    required this.firstName,
    required this.lastName,
    required this.displayName,
    required this.email,
    this.updatedAt,
  });

  final String firstName;
  final String lastName;
  final String displayName;
  final String email;
  final DateTime? updatedAt;

  static String composeDisplayName(String firstName, String lastName) {
    return '${firstName.trim()} ${lastName.trim()}'.trim();
  }

  static bool hasAnyName(String firstName, String lastName) {
    return firstName.trim().isNotEmpty || lastName.trim().isNotEmpty;
  }

  factory UserProfile.fromFirestore(Map<String, dynamic> data) {
    DateTime? updated;
    final raw = data['updatedAt'];
    if (raw is Timestamp) updated = raw.toDate();
    return UserProfile(
      firstName: (data['firstName'] as String?) ?? '',
      lastName: (data['lastName'] as String?) ?? '',
      displayName: (data['displayName'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      updatedAt: updated,
    );
  }

  Map<String, dynamic> toFirestore({required FieldValue updatedAt}) {
    final display = composeDisplayName(firstName, lastName);
    return {
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'displayName': display,
      'email': email.trim(),
      'updatedAt': updatedAt,
    };
  }
}
