import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:projectapp/constant.dart';
import 'package:projectapp/model/groupchat.dart';

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
  double? latitude;
  double? longitude;

  @override
  void initState() {
    super.initState();
    _fetchGroupDetails();
    _joinGroup();
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
      });
    }
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

  Future<void> _leaveGroup() async {
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('userlist')
        .doc(widget.currentUserId)
        .delete();

    Navigator.pop(context);
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

    return doc.exists ? doc['fname'] : 'Unknown User';
  }

  Future<void> _changeGroupStatus() async {
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ยืนยันการเปลี่ยนสถานะ'),
          content: Text('คุณต้องการเปลี่ยนสถานะของกลุ่มนี้หรือไม่?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _changeGroupStatus();
              },
              child: Text('ยืนยัน'),
            ),
          ],
        );
      },
    );
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
            icon: Icon(Icons.exit_to_app),
            onPressed: _leaveGroup,
          ),
        ],
      ),
      body: Container(
        color: Colors.pink[100],
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
                      IconButton(
                        icon: Icon(Icons.edit),
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
                      String messageText = messageData['text'];
                      String senderId = messageData['senderId'];
                      var setTime = messageData['setTime'];

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
                                  return Text(
                                    userName,
                                    style: GoogleFonts.anuphan(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
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
                                child: Text(
                                  messageText,
                                  style: GoogleFonts.anuphan(fontSize: 16),
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
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'พิมพ์ข้อความ...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: _sendMessage,
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