import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:projectapp/screen/chatgroup.dart';
import 'package:projectapp/screen/createpost.dart';

class SharingScreen extends StatelessWidget {
  final currentUser =
      FirebaseAuth.instance.currentUser; // รับ userId ของผู้ใช้ที่ล็อกอิน
  // เพิ่มใน constructor

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[100],
      appBar: AppBar(
        title: Text('หน้าแชร์ซื้อสินค้า'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return createpostScreen(); // หน้า CreatePost ของคุณ
                }),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('groups').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('ไม่มีข้อมูลกลุ่มที่สร้างไว้'));
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: snapshot.data!.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              String groupId = doc.id; // ดึง document ID มาใช้เป็น groupId
              String groupName = data['groupName'] ?? 'ชื่อกลุ่ม';
              String groupImage = data['groupImage'] ?? '';
              int groupSize = data['groupSize'] ?? 2;
              int groupType = data['groupType'] ?? 1;

              return buildGroupCard(
                context,
                groupId,
                groupName,
                groupImage,
                groupSize,
                groupType,
                currentUser!.uid, // ใช้ currentUser?.uid ที่นี่
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget buildGroupCard(BuildContext context, String groupId, String groupName,
      String groupImage, int groupSize, int groupType, String currentUserId) {
    // รับ currentUserId
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatGroupScreen(
              groupId: groupId, // ส่ง groupId ของกลุ่มแชท
              currentUserId:
                  currentUserId, // ส่ง currentUserId ของผู้ใช้ที่ล็อกอิน
            ),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: groupImage.isNotEmpty
                        ? NetworkImage(groupImage)
                        : AssetImage('assets/default_image.png')
                            as ImageProvider,
                    radius: 30,
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(groupName,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('สมาชิก: $groupSize คน'),
                    ],
                  ),
                  Spacer(),
                  Text('ประเภท $groupType',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
