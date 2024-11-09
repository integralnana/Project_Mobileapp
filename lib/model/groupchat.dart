import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GroupChat {
  String groupId;
  String groupName;
  String groupDesc;
  String groupImage;
  int groupSize;
  int groupType;
  DateTime setTime;
  double latitude;
  double longitude;
  String groupStatus;
  String userId;
  String username;

  // เพิ่มรายการวันในภาษาไทย
  static const List<String> thaiDays = [
    'วันอาทิตย์',
    'วันจันทร์',
    'วันอังคาร',
    'วันพุธ',
    'วันพฤหัสบดี',
    'วันศุกร์',
    'วันเสาร์'
  ];

  // เพิ่มรายการเดือนในภาษาไทย
  static const List<String> thaiMonths = [
    'มกราคม',
    'กุมภาพันธ์',
    'มีนาคม',
    'เมษายน',
    'พฤษภาคม',
    'มิถุนายน',
    'กรกฎาคม',
    'สิงหาคม',
    'กันยายน',
    'ตุลาคม',
    'พฤศจิกายน',
    'ธันวาคม'
  ];

  GroupChat({
    required this.groupId,
    required this.groupName,
    required this.groupDesc,
    required this.groupImage,
    required this.groupSize,
    required this.groupType,
    required this.setTime,
    required this.latitude,
    required this.longitude,
    required this.groupStatus,
    required this.userId,
    required this.username,
  });

  // เพิ่มเมธอดสำหรับแปลงวันที่เป็นภาษาไทย
  String getThaiFormattedDate() {
    String thaiDay = thaiDays[setTime.weekday % 7];
    String thaiMonth = thaiMonths[setTime.month - 1];
    int thaiYear = setTime.year + 543;
    String time = DateFormat('HH:mm').format(setTime);

    return '$thaiDay ${setTime.day} $thaiMonth $thaiYear $time น.';
  }

  // เพิ่มเมธอดสำหรับแปลงเฉพาะเวลา
  String getThaiFormattedTime() {
    return DateFormat('HH:mm').format(setTime) + ' น.';
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'groupDesc': groupDesc,
      'groupImage': groupImage,
      'groupSize': groupSize,
      'groupType': groupType,
      'setTime': setTime.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'groupStatus': groupStatus,
      'userId': userId,
      'username': username,
    };
  }

  factory GroupChat.fromJson(Map<String, dynamic> json) {
    return GroupChat(
        groupId: json['groupId'].toString(),
        groupName: json['groupName'].toString(),
        groupDesc: json['groupDesc'].toString(),
        groupImage: json['groupImage'].toString(),
        groupSize: json['groupSize'] is String
            ? int.parse(json['groupSize'])
            : json['groupSize'] as int,
        groupType: json['groupType'] is String
            ? int.parse(json['groupType'])
            : json['groupType'] as int,
        setTime: json['setTime'] is String
            ? DateTime.parse(json['setTime'])
            : (json['setTime'] as Timestamp).toDate(),
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        userId: json['userId'].toString(),
        username: json['username'].toString(),
        groupStatus: json['groupStatus'].toString());
  }

  // เพิ่มเมธอดสแตติกสำหรับแปลงวันที่จาก Timestamp หรือ DateTime
  static String formatThaiDateTime(dynamic timestamp) {
    if (timestamp == null) return 'ไม่สามารถแสดงเวลาได้';

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else if (timestamp is String) {
      try {
        dateTime = DateTime.parse(timestamp);
      } catch (e) {
        return 'รูปแบบเวลาไม่ถูกต้อง';
      }
    } else {
      return 'ไม่สามารถแสดงเวลาได้';
    }

    String thaiDay = thaiDays[dateTime.weekday % 7];
    String thaiMonth = thaiMonths[dateTime.month - 1];
    int thaiYear = dateTime.year + 543;
    String time = DateFormat('HH:mm').format(dateTime);

    return '$thaiDay ${dateTime.day} $thaiMonth $thaiYear $time น.';
  }
}
