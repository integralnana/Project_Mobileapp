class GroupChat {
  String groupId;
  String groupName;
  String groupImage;
  int groupSize;
  int groupType;

  GroupChat({
    required this.groupId,
    required this.groupName,
    required this.groupImage,
    required this.groupSize,
    required this.groupType,
  });

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'groupImage': groupImage,
      'groupSize': groupSize,
      'groupType': groupType,
    };
  }

  factory GroupChat.fromJson(Map<String, dynamic> json) {
    return GroupChat(
      groupId: json['groupId'],
      groupName: json['groupName'],
      groupImage: json['groupImage'],
      groupSize: json['groupSize'],
      groupType: json['groupType'],
    );
  }
}