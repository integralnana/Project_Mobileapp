import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:projectapp/constant.dart';
import 'package:projectapp/model/groupchat.dart';
import 'package:projectapp/screen/showchat.dart';

class ChatGroupScreen extends StatefulWidget {
  final String groupId;
  final String currentUserId;

  ChatGroupScreen({required this.groupId, required this.currentUserId});

  @override
  _ChatGroupScreenState createState() => _ChatGroupScreenState();
}

class _ChatGroupScreenState extends State<ChatGroupScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? groupName;
  String? groupStatus;
  String? userId;
  double? latitude;
  double? longitude;
  String? groupLeaderId;
  bool isGroupLeader = false;
  File? _selectedImage;
  bool hasConfirmedPurchase = false;
  int? groupSize;

  @override
  void initState() {
    super.initState();
    _fetchGroupDetails();
    _joinGroup();
    _checkUserConfirmation();
  }

  Future<void> _fetchGroupDetails() async {
    DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .get();

    if (groupSnapshot.exists) {
      setState(() {
        groupName = groupSnapshot['groupName'];
        groupStatus = groupSnapshot['groupStatus'].toString();
        latitude = groupSnapshot['latitude'];
        longitude = groupSnapshot['longitude'];
        groupLeaderId = groupSnapshot['userId'];
        groupSize = groupSnapshot['groupSize'] ?? 0;
        isGroupLeader = groupLeaderId == widget.currentUserId;
      });
    }
  }

  Future<void> _kickMember(String userId) async {
    if (!isGroupLeader) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('เฉพาะหัวหน้ากลุ่มเท่านั้นที่สามารถเตะสมาชิกออกได้')),
      );
      return;
    }

    if (groupStatus == '3') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('ไม่สามารถเตะสมาชิกออกได้ในช่วงดำเนินการนัดรับ')),
      );
      return;
    }
    if (userId == widget.currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('คุณไม่สามารถเตะตัวเองออกจากกลุ่มได้')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ยืนยันการเตะผู้ใช้'),
          content: Text('คุณต้องการเตะผู้ใช้นี้หรือไม่?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () async {
                // ฟังก์ชันเตะสมาชิกออกจากกลุ่ม
                await FirebaseFirestore.instance
                    .collection('groups')
                    .doc(widget.groupId)
                    .collection('pending')
                    .doc(userId)
                    .delete();

                await FirebaseFirestore.instance
                    .collection('groups')
                    .doc(widget.groupId)
                    .collection('userlist')
                    .doc(userId)
                    .delete();

                // ปิด dialog หลังจากทำงานเสร็จ
                Navigator.of(context).pop();

                // แสดง SnackBar แจ้งเตือน
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('เตะสมาชิกออกจากกลุ่มเรียบร้อย')),
                );
              },
              child: Text('ยืนยัน'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _sendImageMessage() async {
    if (_selectedImage != null) {
      try {
        final storageRef = FirebaseStorage.instance.ref().child(
            'groupFiles/${widget.groupId}/${widget.currentUserId}/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await storageRef.putFile(_selectedImage!);
        final imageUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('messages')
            .add({
          'type': 'image',
          'imageUrl': imageUrl,
          'senderId': widget.currentUserId,
          'setTime': FieldValue.serverTimestamp(),
        });

        // ล้างสถานะการเลือกรูปภาพ
        setState(() {
          _selectedImage = null;
        });
      } catch (e) {
        print('Error uploading image: $e');
      }
    }
  }

  void _cancelSelectedImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _checkUserConfirmation() async {
    DocumentSnapshot confirmDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('confirmations')
        .doc(widget.currentUserId)
        .get();

    setState(() {
      hasConfirmedPurchase = confirmDoc.exists;
    });
  }

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('messages')
          .add({
        'text': _messageController.text,
        'senderId': widget.currentUserId,
        'setTime': FieldValue.serverTimestamp(),
        'type': 'text',
      });

      _messageController.clear();
    }
  }

  Future<void> _joinGroup() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('userlist')
        .doc(widget.currentUserId)
        .get();

    if (!userDoc.exists) {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('userlist')
          .doc(widget.currentUserId)
          .set({'joinedAt': FieldValue.serverTimestamp()});
    }
  }

  void _showuserlist() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: double.maxFinite,
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'รายชื่อสมาชิกในกลุ่ม',
                      style: GoogleFonts.anuphan(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('groups')
                          .doc(widget.groupId)
                          .collection('userlist')
                          .snapshots(),
                      builder: (context, userlistSnapshot) {
                        if (userlistSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }

                        if (!userlistSnapshot.hasData ||
                            userlistSnapshot.data!.docs.isEmpty) {
                          return Text('0/$groupSize');
                        }

                        return Text(
                          '${userlistSnapshot.data!.docs.length}/$groupSize',
                          style: GoogleFonts.anuphan(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  constraints: BoxConstraints(maxHeight: 300),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('groups')
                        .doc(widget.groupId)
                        .collection('userlist')
                        .snapshots(),
                    builder: (context, userlistSnapshot) {
                      if (userlistSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (!userlistSnapshot.hasData ||
                          userlistSnapshot.data!.docs.isEmpty) {
                        return Center(
                            child: Text('ไม่มีสมาชิกในกลุ่มนี้',
                                style: GoogleFonts.anuphan()));
                      }

                      // Separate leader and members
                      List<QueryDocumentSnapshot> members =
                          userlistSnapshot.data!.docs;
                      List<QueryDocumentSnapshot> normalMembers = [];
                      QueryDocumentSnapshot? leader;

                      for (var doc in members) {
                        if (doc.id == groupLeaderId) {
                          leader = doc;
                        } else {
                          normalMembers.add(doc);
                        }
                      }

                      return ListView(
                        shrinkWrap: true,
                        children: [
                          // Show leader first
                          if (leader != null)
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(leader.id)
                                  .get(),
                              builder: _buildUserListTile,
                            ),
                          // Divider after leader
                          if (leader != null) Divider(thickness: 2),
                          // Show other members
                          ...normalMembers
                              .map((doc) => FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(doc.id)
                                        .get(),
                                    builder: _buildUserListTile,
                                  )),
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('ปิด', style: GoogleFonts.anuphan()),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _leaveGroup() async {
    if (isGroupLeader) {
      QuerySnapshot memberSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('userlist')
          .get();

      if (memberSnapshot.docs.length > 1) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('ไม่สามารถออกจากกลุ่มได้'),
              content: Text('คุณเป็นหัวหน้ากลุ่ม ไม่สามารถออกจากกลุ่มได้'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('ตกลง'),
                ),
              ],
            );
          },
        );
        return;
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('ออกจากกลุ่ม'),
              content: Text('ต้องการออกจากกลุ่มใช่ไหม'),
              actions: <Widget>[
                TextButton(
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ออกจากกลุ่มแล้ว')));
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ShowChatScreen()));
                    await FirebaseFirestore.instance
                        .collection('groups')
                        .doc(widget.groupId)
                        .collection('userlist')
                        .doc(widget.currentUserId)
                        .delete();
                    await FirebaseFirestore.instance
                        .collection('groups')
                        .doc(widget.groupId)
                        .delete();
                  },
                  child: Text('ตกลง'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('ยกเลิก'),
                ),
              ],
            );
          },
        );
      }
    }

    if (groupStatus == '3') {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('ไม่สามารถออกจากกลุ่มได้'),
            content: Text('ไม่สามารถออกจากกลุ่มในช่วงดำเนินการนัดรับได้'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('ตกลง'),
              ),
            ],
          );
        },
      );
      return;
    }

    if (!isGroupLeader) {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('pending')
          .doc(widget.currentUserId)
          .delete();
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('userlist')
          .doc(widget.currentUserId)
          .delete();
      Navigator.pop(context);
    }
  }

  Future<void> _confirmPurchase() async {
    if (hasConfirmedPurchase) return;

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('confirmations')
        .doc(widget.currentUserId)
        .set({
      'confirmedAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      hasConfirmedPurchase = true;
    });
  }

  Future<void> _cancelConfirmation() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ยืนยันการยกเลิก'),
          content: Text('คุณต้องการยกเลิกการยืนยันการซื้อหรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ไม่'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('groups')
                    .doc(widget.groupId)
                    .collection('confirmations')
                    .doc(widget.currentUserId)
                    .delete();

                setState(() {
                  hasConfirmedPurchase = false;
                });
                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ยกเลิกการยืนยันการซื้อแล้ว')),
                );
              },
              child: Text('ใช่'),
            ),
          ],
        );
      },
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return DateFormat('HH:mm').format(timestamp.toDate());
    } else if (timestamp is String) {
      return timestamp;
    } else {
      return 'Invalid timestamp';
    }
  }

  Future<String> _getUserName(String userId) async {
    DocumentSnapshot doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    return doc.exists ? doc['username'] : 'Unknown User';
  }

  Future<void> _changeGroupStatus() async {
    if (!isGroupLeader) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('เฉพาะหัวหน้ากลุ่มเท่านั้นที่สามารถเปลี่ยนสถานะได้')),
      );
      return;
    }

    if (groupStatus == '1') {
      QuerySnapshot members = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('userlist')
          .get();
      if (members.size < groupSize!) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ต้องรอให้สมาชิกทุกคนเข้าร่วมกลุ่มก่อน')),
        );
        return;
      }
    }

    if (groupStatus == '2') {
      // Check if all members have confirmed
      QuerySnapshot confirmations = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('confirmations')
          .get();

      QuerySnapshot members = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('userlist')
          .get();

      if (confirmations.size < members.size) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ต้องรอให้สมาชิกทุกคนยืนยันการซื้อก่อน')),
        );
        return;
      }
    }

    if (groupStatus != null) {
      int newStatus = (int.parse(groupStatus!) % 4) + 1;
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .update({
        'groupStatus': newStatus,
      });
      setState(() {
        groupStatus = newStatus.toString();
      });
    }
  }

  void _showStatusChangeConfirmation() {
    if (!isGroupLeader) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('เฉพาะหัวหน้ากลุ่มเท่านั้นที่สามารถเปลี่ยนสถานะได้')),
      );
      return;
    }
    if (groupStatus == "3") {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.yellow[100],
            contentPadding: EdgeInsets.all(16.0),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    _getStatusText(int.parse(groupStatus!)),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, size: 48),
                Text(
                  _getStatusText(int.parse(groupStatus!) + 1),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _changeGroupStatus();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 71, 255, 78),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: Text('ยืนยันการซื้อ',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 239, 108, 98),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: Text('ยกเลิก',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.yellow[100],
            contentPadding: EdgeInsets.all(16.0),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    _getStatusText(int.parse(groupStatus!)),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, size: 48),
                Text(
                  _getStatusText(int.parse(groupStatus!) + 1),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                ),
                Icon(Icons.arrow_drop_down, size: 48),
                Text(
                  _getStatusText(int.parse(groupStatus!) + 2),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _changeGroupStatus();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 71, 255, 78),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: Text('ยืนยันการซื้อ',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 239, 108, 98),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: Text('ยกเลิก',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
              ),
            ],
          );
        },
      );
    }
  }

  void _showLocationDialog(BuildContext context) {
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ตำแหน่งไม่พร้อมใช้งาน')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ตำแหน่งที่ปักหมุด'),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(latitude!, longitude!),
                zoom: 14.0,
              ),
              markers: {
                Marker(
                  markerId: MarkerId('selected-location'),
                  position: LatLng(latitude!, longitude!),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ),
                ),
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ตกลง'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserListTile(
    BuildContext context,
    AsyncSnapshot<DocumentSnapshot> userSnapshot,
  ) {
    if (userSnapshot.connectionState == ConnectionState.waiting) {
      return ListTile(
        leading: CircleAvatar(child: CircularProgressIndicator()),
        title: Text('กำลังโหลด...'),
      );
    }

    if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
      return SizedBox.shrink();
    }

    Map<String, dynamic> userData =
        userSnapshot.data!.data() as Map<String, dynamic>;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            userData['imageUrl'] != null && userData['imageUrl'].isNotEmpty
                ? NetworkImage(userData['imageUrl'])
                : null,
        child: userData['imageUrl'] == null || userData['imageUrl'].isEmpty
            ? Icon(Icons.person)
            : null,
      ),
      title: Text(
        userData['username'] ?? 'ไม่มีชื่อผู้ใช้',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${userData['fname'] ?? ''} ${userData['lname'] ?? ''}',
        style: GoogleFonts.anuphan(),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (userSnapshot.data!.id == groupLeaderId)
            FaIcon(
              FontAwesomeIcons.crown,
              size: 16,
              color: Colors.yellow,
            ),
          SizedBox(width: 8),
          if (isGroupLeader &&
              groupStatus != '3' &&
              userSnapshot.data!.id != widget.currentUserId)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _kickMember(userSnapshot.data!.id),
              color: Colors.red,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
            child: Text('แชท',
                style: GoogleFonts.anuphan(fontWeight: FontWeight.bold))),
        backgroundColor: AppTheme.appBarColor,
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: _showuserlist,
          ),
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: _leaveGroup,
          ),
        ],
      ),
      body: Container(
        color: AppTheme.backgroundColor,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8),
              color: Color.fromARGB(212, 219, 219, 219),
              child: Center(
                child: Text(
                  groupName ?? 'กำลังโหลดชื่อกลุ่ม...',
                  style: GoogleFonts.anuphan(
                      fontSize: 30, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4),
              color: Color.fromARGB(255, 195, 195, 195),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      RichText(
                        text: TextSpan(
                          text: 'สถานะ : ',
                          style: GoogleFonts.anuphan(
                              fontSize: 18, color: Colors.black),
                          children: [
                            TextSpan(
                              text: groupStatus != null
                                  ? _getStatusText(int.parse(groupStatus!))
                                  : 'กำลังโหลดสถานะ...',
                              style: GoogleFonts.anuphan(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      if (isGroupLeader)
                        if (groupStatus != "4")
                          IconButton(
                            icon: Icon(Icons.play_circle_fill),
                            color: Color.fromARGB(255, 46, 95, 179),
                            onPressed: _showStatusChangeConfirmation,
                          ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => _showLocationDialog(context),
                    child: Text(
                      'ดูสถานที่นัดรับ',
                      style: GoogleFonts.anuphan(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8),
              color: const Color.fromARGB(212, 219, 219, 219),
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('groups')
                    .doc(widget.groupId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  if (snapshot.hasData) {
                    var setTime = snapshot.data!['setTime'];
                    return Text(
                      'เวลานัดรับสินค้า: ${GroupChat.formatThaiDateTime(setTime)}',
                      style: GoogleFonts.anuphan(fontWeight: FontWeight.bold),
                    );
                  }
                  return Text('ไม่สามารถโหลดข้อมูลได้');
                },
              ),
            ),
            if (groupStatus == '2')
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('groups')
                        .doc(widget.groupId)
                        .collection('confirmations')
                        .snapshots(),
                    builder: (context, snapshot) {
                      int confirmedCount =
                          snapshot.hasData ? snapshot.data!.size : 0;
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            child: Text(
                              'ยืนยันการซื้อแล้ว: $confirmedCount/${groupSize ?? 0} คน',
                              style: GoogleFonts.anuphan(
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  if (!hasConfirmedPurchase)
                    ElevatedButton(
                      onPressed: _confirmPurchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        minimumSize: const Size(100, 25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          Text('ยืนยันการซื้อ', style: GoogleFonts.anuphan()),
                    ),
                  if (hasConfirmedPurchase)
                    ElevatedButton(
                      onPressed: _cancelConfirmation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size(100, 25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'ยกเลิกการยืนยัน',
                        style: GoogleFonts.anuphan(color: Colors.white),
                      ),
                    ),
                ],
              ),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('groups')
                    .doc(widget.groupId)
                    .collection('messages')
                    .orderBy('setTime', descending: true)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                        child: Text(
                      'ไม่มีข้อความในกลุ่มนี้',
                      style: GoogleFonts.anuphan(),
                    ));
                  }

                  return ListView.builder(
                    reverse: true,
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var messageData = snapshot.data!.docs[index];
                      String senderId = messageData['senderId'];
                      var setTime = messageData['setTime'];
                      String? messageType = messageData[
                          'type']; // เพิ่มการตรวจสอบประเภทของข้อความ
                      bool isCurrentUser = senderId == widget.currentUserId;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        child: Align(
                          alignment: isCurrentUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: isCurrentUser
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              FutureBuilder<String>(
                                future: _getUserName(senderId),
                                builder: (context, snapshot) {
                                  String userName =
                                      snapshot.data ?? 'กำลังโหลดชื่อ...';
                                  return Row(
                                    mainAxisAlignment: isCurrentUser
                                        ? MainAxisAlignment.end
                                        : MainAxisAlignment.start,
                                    children: [
                                      if (senderId == groupLeaderId)
                                        const Padding(
                                          padding: EdgeInsets.only(right: 6.0),
                                          child: FaIcon(
                                            FontAwesomeIcons.crown,
                                            size: 16,
                                            color: Colors.yellow,
                                          ),
                                        ),
                                      Text(
                                        userName,
                                        style: GoogleFonts.anuphan(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isCurrentUser
                                      ? Colors.blue[100]
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: messageType == 'image'
                                    ? Image.network(
                                        messageData['imageUrl'],
                                        width: 200,
                                        height: 200,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                      )
                                    : Text(
                                        messageData['text'] ?? '',
                                        style:
                                            GoogleFonts.anuphan(fontSize: 16),
                                      ),
                              ),
                              Text(
                                setTime != null
                                    ? _formatTimestamp(setTime)
                                    : 'กำลังประมวลผล...',
                                style: GoogleFonts.anuphan(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  if (_selectedImage == null)
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'พิมพ์ข้อความ...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.image),
                        label: Text(
                          'ยกเลิก',
                          style: GoogleFonts.anuphan(),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        onPressed: _cancelSelectedImage,
                      ),
                    ),
                  if (_selectedImage == null)
                    IconButton(
                      icon: Icon(Icons.photo),
                      onPressed: _selectImage,
                    ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () {
                      if (_selectedImage != null) {
                        _sendImageMessage();
                      } else {
                        _sendMessage();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(int status) {
    switch (status) {
      case 1:
        return 'กำลังยืนยันการแชร์';
      case 2:
        return 'กำลังดำเนินการซื้อ';
      case 3:
        return 'กำลังดำเนินการนัดรับ';
      case 4:
        return 'นัดรับสำเร็จแล้ว';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }
}
