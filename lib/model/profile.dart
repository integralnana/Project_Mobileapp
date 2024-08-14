// ignore_for_file: public_member_api_docs, sort_constructors_first
// lib/models/user_model.dart

class Profile {
  String userId;
  String userType;
  String email;
  String phone;
  String imageUrl;
  String fname;
  String lname;

  Profile({
    required this.userId,
    required this.userType,
    required this.email,
    required this.phone,
    required this.imageUrl,
    required this.fname,
    required this.lname,
  });

  // Convert UserModel object to map (for saving to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'phone': phone,
      'imageUrl': imageUrl,
      'userType' : userType,
      'fname' : fname,
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      userId: map['userId'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      userType: map['userType'] ?? '',
      fname: map['fmane'] ?? '',
      lname: map['lmane'] ?? '',
    );
  }
}
