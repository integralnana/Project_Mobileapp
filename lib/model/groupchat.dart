import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GroupChat {
  String groupId;
  String groupName;
  String groupDesc;
  String groupImage;
  int groupSize;
  int groupType;
  Timestamp setTime;
  double latitude;
  double longitude;
  String groupStatus;
  String userId;
  String username;
  String groupCate;
  int groupGenre;

  static const List<String> categories = [
    'อาหารและเครื่องดื่ม',
    'เครื่องแต่งกาย',
    'อิเล็กทรอนิกส์',
    'หนังสือ',
    'เครื่องเขียน',
    'กีฬา',
    'เครื่องใช้ในบ้าน',
    'แฟชั่น',
    'เครื่องสำอาง',
    'สุขภาพ',
    'บริการอื่นๆ'
  ];

  static const List<String> thaiDays = [
    'วันอาทิตย์',
    'วันจันทร์',
    'วันอังคาร',
    'วันพุธ',
    'วันพฤหัสบดี',
    'วันศุกร์',
    'วันเสาร์'
  ];

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
    required this.groupCate,
    required this.groupGenre,
  });

  get userlist => null;

  String getThaiFormattedDate() {
    DateTime dateTime = setTime.toDate();
    String thaiDay = thaiDays[dateTime.weekday % 7];
    String thaiMonth = thaiMonths[dateTime.month - 1];
    int thaiYear = dateTime.year + 543;
    String time = DateFormat('HH:mm').format(dateTime);

    return '$thaiDay ${dateTime.day} $thaiMonth $thaiYear $time น.';
  }

  String getThaiFormattedTime() {
    DateTime dateTime = setTime.toDate();
    return DateFormat('HH:mm').format(dateTime) + ' น.';
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'groupDesc': groupDesc,
      'groupImage': groupImage,
      'groupSize': groupSize,
      'groupType': groupType,
      'setTime': setTime, // ส่ง Timestamp โดยตรง
      'latitude': latitude,
      'longitude': longitude,
      'groupStatus': groupStatus,
      'userId': userId,
      'username': username,
      'groupCate': groupCate,
      'groupGenre': groupGenre
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
        groupGenre: json['groupGenre'] is String
            ? int.parse(json['groupGenre'])
            : json['groupType'] as int,
        setTime: json['setTime'] as Timestamp, // แก้ไขให้รับ Timestamp โดยตรง
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        userId: json['userId'].toString(),
        username: json['username'].toString(),
        groupCate: json['groupCate'].toString(),
        groupStatus: json['groupStatus'].toString());
  }

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