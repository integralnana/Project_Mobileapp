// ignore_for_file: public_member_api_docs, sort_constructors_first
// lib/models/user_model.dart

class Profile {
  String userId;
  String email;
  String phone;
  String imageUrl;
  String fname;
  String lname;
  String username;
  num point;
  String status;

  Profile(
      {required this.userId,
      required this.email,
      required this.phone,
      required this.imageUrl,
      required this.fname,
      required this.lname,
      required this.status,
      required this.point,
      required this.username});

  // Convert UserModel object to map (for saving to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'phone': phone,
      'imageUrl': imageUrl,
      'fname': fname,
      'lname': lname,
      'point': point,
      'username': username,
      'status': status
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      userId: map['userId'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      fname: map['fname'] ?? '',
      lname: map['lname'] ?? '',
      point: map['point'] ?? '',
      status: map['status'] ?? '',
      username: map['username'] ?? '',
    );
  }
}
