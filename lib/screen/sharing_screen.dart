import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:projectapp/constant.dart';
import 'package:projectapp/model/groupchat.dart';
import 'package:projectapp/screen/chatgroup.dart';
import 'package:projectapp/screen/createpost.dart';

class SharingScreen extends StatelessWidget {
  final currentUser = FirebaseAuth.instance.currentUser;

  Future<String?> _getUserProfileImage(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists && userDoc['imageUrl'] != null) {
        return userDoc['imageUrl'];
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching user profile image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[100],
      appBar: AppBar(
        title: Text('หน้าแชร์ซื้อสินค้า'),
        backgroundColor: AppTheme.appBarColor,
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
              return FutureBuilder<String?>(
                future: _getUserProfileImage(data['userId']),
                builder: (context, AsyncSnapshot<String?> imageSnapshot) {
                  return buildGroupCard(
                      context, data, doc.id, imageSnapshot.data);
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget buildGroupCard(BuildContext context, Map<String, dynamic> data,
      String groupId, String? profileImageUrl) {
    String groupName = data['groupName'] ?? 'ชื่อกลุ่ม';
    String groupImage = data['groupImage'] ?? '';
    int groupSize = data['groupSize'] ?? 2;
    String groupDesc = data['groupDesc'] ?? 'ไม่มีคำอธิบาย';
    String username = data['username'] ?? 'Unknown User';
    double latitude = data['latitude'] ?? 0.0;
    double longitude = data['longitude'] ?? 0.0;
    int groupType = data['groupType'] ?? 1;
    String formattedDateTime = 'ไม่ระบุเวลา';

    try {
      var setTime = data['setTime'];
      if (setTime is Timestamp) {
        formattedDateTime = GroupChat.formatThaiDateTime(setTime);
      } else if (setTime is String) {
        formattedDateTime = GroupChat.formatThaiDateTime(setTime);
      } else {
        print('Unexpected type for setTime: ${setTime.runtimeType}');
      }
    } catch (e) {
      print('Error formatting date: $e');
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: profileImageUrl != null
                  ? NetworkImage(profileImageUrl)
                  : AssetImage('assets/default_user_image.png')
                      as ImageProvider,
              radius: 20,
            ),
            title:
                Text(username, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(formattedDateTime), // ใช้ formattedDateTime ที่นี่
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              groupName,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('$groupSize คน',
                      style:
                          TextStyle(color: Colors.red.shade800, fontSize: 14)),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    groupType == 1 ? 'โอนก่อน' : 'จ่ายหลังนัดรับ',
                    style: TextStyle(color: Colors.blue.shade800, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 200,
            width: double.infinity,
            child: Image.network(
              groupImage,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset('assets/default_group_image.png',
                    fit: BoxFit.cover);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('รายละเอียด',
                    style: GoogleFonts.anuphan(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(groupDesc,
                    style: GoogleFonts.anuphan(color: Colors.grey[700])),
              ],
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _showLocationDialog(context, latitude, longitude);
                  },
                  icon: Icon(Icons.location_on, size: 18),
                  label: Text(
                    'ดูสถานที่นัดรับ',
                    style: GoogleFonts.anuphan(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
                ElevatedButton(
                  onPressed: () {
                    _joinGroup(context, groupId);
                  },
                  child: Text(
                    'เข้าร่วมแชร์',
                    style: GoogleFonts.anuphan(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationDialog(
      BuildContext context, double latitude, double longitude) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'สถานที่นัดรับ',
            style: GoogleFonts.anuphan(),
          ),
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
              child: Text(
                'ตกลง',
                style: GoogleFonts.anuphan(),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _joinGroup(BuildContext context, String groupId) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    DocumentReference groupRef =
        FirebaseFirestore.instance.collection('groups').doc(groupId);
    DocumentSnapshot groupDoc = await groupRef.get();

    if (groupDoc.exists) {
      var data = groupDoc.data() as Map<String, dynamic>;
      int groupSize = data['groupSize'];

      // ตรวจสอบสมาชิกที่มีอยู่ใน userlist
      QuerySnapshot userList = await groupRef.collection('userlist').get();
      bool userExists =
          userList.docs.any((doc) => doc['userId'] == currentUser.uid);

      // ถ้าผู้ใช้มีอยู่ใน userlist แล้วให้ไปที่ ChatGroupScreen
      if (userExists) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatGroupScreen(
              groupId: groupId,
              currentUserId: currentUser.uid,
            ),
          ),
        );
        return;
      }

      // ตรวจสอบจำนวนสมาชิก
      if (userList.docs.length < groupSize) {
        // เพิ่มสมาชิก
        await groupRef.collection('userlist').doc(currentUser.uid).set({
          'userId': currentUser.uid,
          'username': 'Your Username',
        });

        // นำทางไปยัง ChatGroupScreen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatGroupScreen(
              groupId: groupId,
              currentUserId: currentUser.uid,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Group is full!')));
      }
    }
  }
}
