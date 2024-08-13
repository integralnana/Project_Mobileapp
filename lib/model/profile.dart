// ignore_for_file: public_member_api_docs, sort_constructors_first
// lib/models/user_model.dart

class Profile {
  String userId;
  String userType;
  String studentId;
  String userNick;
  String email;
  String phone;
  String imageUrl;

  Profile({
    required this.userId,
    required this.userType,
    required this.studentId,
    required this.userNick,
    required this.email,
    required this.phone,
    required this.imageUrl,
  });

  // Convert UserModel object to map (for saving to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'phone': phone,
      'imageUrl': imageUrl,
      'userNick' : userNick,
      'userType' : userType,
      'studentId' : studentId,
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      userId: map['userId'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      userType: map['userType'] ?? '',
      userNick: map['userNick'] ?? '',
      studentId: map['studentId'] ?? '',
    );
  }
}
