class GroupChat {
  String groupId;
  String groupName;
  String groupDesc;
  String groupImage;
  int groupSize;
  int groupType;
  DateTime createdAt;
  double latitude; // พิกัดละติจูด
  double longitude; // พิกัดลองจิจูด
  String userId; // userId ของผู้สร้างกลุ่ม
  String username; // ชื่อของผู้สร้างกลุ่ม

  GroupChat({
    required this.groupId,
    required this.groupName,
    required this.groupDesc,
    required this.groupImage,
    required this.groupSize,
    required this.groupType,
    required this.createdAt,
    required this.latitude,
    required this.longitude,
    required this.userId, // ต้องใส่ userId
    required this.username, // ต้องใส่ username
  });

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'groupDesc': groupDesc,
      'groupImage': groupImage,
      'groupSize': groupSize,
      'groupType': groupType,
      'createdAt': createdAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'userId': userId, // บันทึก userId
      'username': username, // บันทึก username
    };
  }

  factory GroupChat.fromJson(Map<String, dynamic> json) {
    return GroupChat(
      groupId: json['groupId'],
      groupName: json['groupName'],
      groupDesc: json['groupDesc'],
      groupImage: json['groupImage'],
      groupSize: json['groupSize'],
      groupType: json['groupType'],
      createdAt: DateTime.parse(json['createdAt']),
      latitude: json['latitude'],
      longitude: json['longitude'],
      userId: json['userId'], // ดึง userId
      username: json['username'], // ดึง username
    );
  }
}
