import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // ใช้สำหรับแปลงเวลา

class ChatGroupScreen extends StatefulWidget {
  final String groupId;
  final String currentUserId; // เพิ่ม userId ของผู้ที่ล็อกอิน

  ChatGroupScreen({required this.groupId, required this.currentUserId});

  @override
  _ChatGroupScreenState createState() => _ChatGroupScreenState();
}

class _ChatGroupScreenState extends State<ChatGroupScreen> {
  final TextEditingController _messageController = TextEditingController();

  // ฟังก์ชันสำหรับส่งข้อความ
  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('messages')
          .add({
        'text': _messageController.text,
        'senderId': widget.currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    return DateFormat('HH:mm')
        .format(timestamp.toDate()); // แปลงเวลาเป็นรูปแบบ HH:mm
  }

  Future<String> _getUserName(String userId) async {
    DocumentSnapshot doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    return doc.exists ? doc['fname'] : 'Unknown User';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Group'),
        backgroundColor: Colors.orange, // เปลี่ยนสีของ AppBar
      ),
      body: Container(
        color: Colors.pink[100], // เปลี่ยนสีพื้นหลัง
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('groups')
                    .doc(widget.groupId)
                    .collection('messages')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('ไม่มีข้อความในกลุ่มนี้'));
                  }

                  return ListView.builder(
                    reverse: true,
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var messageData = snapshot.data!.docs[index];
                      String messageText = messageData['text'];
                      String senderId = messageData['senderId'];
                      Timestamp createdAt = messageData['createdAt'];

                      // ตรวจสอบว่าใครเป็นผู้ส่งข้อความ
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
                              // ใช้ FutureBuilder เพื่อดึงชื่อผู้ส่ง
                              FutureBuilder<String>(
                                future: _getUserName(senderId),
                                builder: (context, snapshot) {
                                  String userName = 'ผู้ใช้'; // ชื่อเริ่มต้น
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    userName = 'กำลังโหลด...';
                                  } else if (snapshot.hasData) {
                                    userName = snapshot.data!;
                                  }
                                  return Text(
                                    isCurrentUser ? 'คุณ' : userName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isCurrentUser
                                          ? Colors.blue[900]
                                          : Colors.black,
                                    ),
                                  );
                                },
                              ),
                              Container(
                                padding: EdgeInsets.all(10),
                                margin: EdgeInsets.only(top: 5),
                                decoration: BoxDecoration(
                                  color: isCurrentUser
                                      ? Colors.blue[200]
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Text(
                                  messageText,
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                              // แสดงเวลาส่งในตำแหน่งที่ถูกต้อง
                              if (!isCurrentUser)
                                Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Text(
                                    _formatTimestamp(createdAt),
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600]),
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.pink, width: 1),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: _sendMessage,
                    color: Colors.pink,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
