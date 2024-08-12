// lib/models/user_model.dart

class Profile {
  String userId;
  String email;
  String phone;
  String gender;
  String imageUrl;

  Profile({
    required this.userId,
    required this.email,
    required this.phone,
    required this.gender,
    required this.imageUrl,
  });

  // Convert UserModel object to map (for saving to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'phone': phone,
      'gender': gender,
      'imageUrl': imageUrl,
    };
  }

  // Create a UserModel object from a map (for fetching from Firestore)
  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      userId: map['userId'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      gender: map['gender'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}
