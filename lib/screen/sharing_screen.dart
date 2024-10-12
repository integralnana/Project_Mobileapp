import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:projectapp/screen/chatgroup.dart';
import 'package:projectapp/screen/createpost.dart';

class SharingScreen extends StatelessWidget {
  final currentUser = FirebaseAuth.instance.currentUser;

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
                MaterialPageRoute(builder: (context) => createpostScreen()),
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
              String groupId = doc.id;
              String groupName = data['groupName'] ?? 'ชื่อกลุ่ม';
              String groupImage = data['groupImage'] ?? '';
              int groupSize = data['groupSize'] ?? 2;
              int groupType = data['groupType'] ?? 1;
              double latitude = data['latitude'] ?? 0.0;
              double longitude = data['longitude'] ?? 0.0;
              String groupDesc = data['groupDesc'] ?? 'ไม่มีคำอธิบาย';
              String username = data['username'] ?? 'Unknown User';
              double rating = data['rating'] ?? 0.0;

              // สมมุติว่ามีการจัดเก็บ profileImage สำหรับผู้ใช้
              String profileImage = data['profileImage'] ??
                  'assets/default_image.png'; // เปลี่ยนให้ตรงกับข้อมูลใน Firestore

              return buildGroupCard(
                context,
                groupId,
                groupName,
                groupImage,
                groupSize,
                groupType,
                latitude,
                longitude,
                currentUser!.uid,
                groupDesc,
                username,
                rating,
                profileImage, // ส่ง profileImage เป็นพารามิเตอร์
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget buildGroupCard(
    BuildContext context,
    String groupId,
    String groupName,
    String groupImage,
    int groupSize,
    int groupType,
    double latitude,
    double longitude,
    String currentUserId,
    String groupDesc,
    String username,
    double rating,
    String profileImage, // รับ profileImage เป็นพารามิเตอร์
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: profileImage.isNotEmpty
                      ? NetworkImage(profileImage)
                      : AssetImage('assets/default_image.png') as ImageProvider,
                  radius: 30,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(username,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          SizedBox(width: 5),
                          Icon(Icons.star, color: Colors.yellow, size: 16),
                          Text(rating.toStringAsFixed(1),
                              style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      Text(groupName, // แสดง groupName ที่นี่
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('สมาชิก: $groupSize คน'),
                      Text('ประเภท $groupType',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text('คำอธิบาย: $groupDesc',
                style: TextStyle(
                    fontStyle: FontStyle.italic, color: Colors.grey[700])),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _showLocationDialog(context, latitude, longitude);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent),
                  child: Text('ดูสถานที่'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatGroupScreen(
                          groupId: groupId,
                          currentUserId: currentUserId,
                        ),
                      ),
                    );
                  },
                  child: Text('เข้าร่วมกลุ่ม'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationDialog(
      BuildContext context, double latitude, double longitude) {
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
                target: LatLng(latitude, longitude),
                zoom: 14.0,
              ),
              markers: {
                Marker(
                  markerId: MarkerId('selected-location'),
                  position: LatLng(latitude, longitude),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed),
                ),
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('ตกลง'),
            ),
          ],
        );
      },
    );
  }
}
