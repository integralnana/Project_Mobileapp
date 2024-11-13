import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:projectapp/constant.dart';
import 'package:projectapp/model/groupchat.dart';
import 'package:projectapp/screen/chatgroup.dart';
import 'package:projectapp/screen/createpost.dart';

class SharingScreen extends StatefulWidget {
  @override
  State<SharingScreen> createState() => _SharingScreenState();
}

class _SharingScreenState extends State<SharingScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;

  String? selectedCategory;
  int? selectedPaymentType;

  Query<Map<String, dynamic>> buildQuery() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('groups')
        .where('groupStatus', isNotEqualTo: 2);

    if (selectedCategory != null) {
      query = query.where('groupCate', isEqualTo: selectedCategory);
    }

    if (selectedPaymentType != null) {
      query = query.where('groupType', isEqualTo: selectedPaymentType);
    }

    return query;
  }

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

  Future<int> _getUserListCount(String groupId) async {
    QuerySnapshot userList = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('userlist')
        .get();
    return userList.docs.length;
  }

  Widget buildFilterDropdowns() {
    return Container(
      color: AppTheme.appBarColor,
      padding: EdgeInsets.all(16.0),
      child: Container(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedCategory,
                    hint: Text('เลือกหมวดหมู่'),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(
                          'ประเภทสินค้า: ทั้งหมด',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      ...GroupChat.categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedCategory = newValue;
                      });
                    },
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.0),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    isExpanded: true,
                    value: selectedPaymentType,
                    hint: Text('ประเภทการชำระ'),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(
                          'ประเภทการชำระ: ทุกประเภท',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      DropdownMenuItem<int?>(
                        value: 1,
                        child: Text('โอนก่อน'),
                      ),
                      DropdownMenuItem<int?>(
                        value: 2,
                        child: Text('จ่ายหลังนัดรับ'),
                      ),
                    ],
                    onChanged: (int? newValue) {
                      setState(() {
                        selectedPaymentType = newValue;
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('หน้าแชร์ซื้อสินค้า'),
        backgroundColor: AppTheme.appBarColor,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreatePostScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          buildFilterDropdowns(),
          Expanded(
            child: StreamBuilder(
              stream: buildQuery().snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  print('Error: ${snapshot.error}'); // เพิ่ม debug
                  return Center(
                      child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('ไม่พบข้อมูลที่ค้นหา',
                            style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: snapshot.data!.docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return FutureBuilder<List<dynamic>>(
                      future: Future.wait([
                        _getUserProfileImage(data['userId']),
                        _getUserListCount(doc.id),
                      ]),
                      builder: (context,
                          AsyncSnapshot<List<dynamic>> combinedSnapshot) {
                        if (combinedSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        String? profileImageUrl = combinedSnapshot.data?[0];
                        int memberCount = combinedSnapshot.data?[1] ?? 0;

                        return buildGroupCard(
                          context,
                          data,
                          doc.id,
                          profileImageUrl,
                          memberCount,
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildGroupCard(
    BuildContext context,
    Map<String, dynamic> data,
    String groupId,
    String? profileImageUrl,
    int currentMemberCount,
  ) {
    String groupName = data['groupName'] ?? 'ชื่อกลุ่ม';
    String groupImage = data['groupImage'] ?? '';
    int groupSize = data['groupSize'] ?? 2;
    String groupDesc = data['groupDesc'] ?? 'ไม่มีคำอธิบาย';
    String username = data['username'] ?? 'Unknown User';
    double latitude = data['latitude'] ?? 0.0;
    double longitude = data['longitude'] ?? 0.0;
    int groupType = data['groupType'] ?? 1;
    String groupCate = data['groupCate'] ?? 'ไม่มีระบุ';
    String formattedDateTime = 'ไม่ระบุเวลา';

    try {
      var setTime = data['setTime'];
      if (setTime is Timestamp) {
        formattedDateTime = GroupChat.formatThaiDateTime(setTime);
      } else if (setTime is String) {
        formattedDateTime = GroupChat.formatThaiDateTime(setTime);
      }
    } catch (e) {
      print('Error formatting date: $e');
    }

    return Card(
      color: AppTheme.cardColor,
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: profileImageUrl != null
                  ? NetworkImage(profileImageUrl)
                  : AssetImage('assets/images/default_user_image.png')
                      as ImageProvider,
              radius: 20,
            ),
            title:
                Text(username, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(formattedDateTime),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    groupName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$currentMemberCount/$groupSize คน',
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
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
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    groupCate,
                    style: TextStyle(color: Colors.blue.shade800, fontSize: 14),
                  ),
                ),
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
                return Image.asset('assets/images/default_group_image.png',
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
                  label: Text('ดูสถานที่นัดรับ',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('groups')
                      .doc(groupId)
                      .collection('userlist')
                      .doc(currentUser?.uid)
                      .snapshots(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.hasData && userSnapshot.data!.exists) {
                      return ElevatedButton(
                        onPressed: () => _joinGroup(context, groupId),
                        child: Text('เข้าร่วมแชร์',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue),
                      );
                    } else {
                      return StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('groups')
                            .doc(groupId)
                            .collection('pending')
                            .doc(currentUser?.uid)
                            .snapshots(),
                        builder: (context, pendingSnapshot) {
                          if (pendingSnapshot.hasData &&
                              pendingSnapshot.data!.exists) {
                            var pendingStatus =
                                pendingSnapshot.data!['request'];
                            if (pendingStatus == 'rejected') {
                              return ElevatedButton(
                                onPressed: () => _joinGroup(context, groupId),
                                child: Text('ขอเข้าร่วม',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            } else {
                              return ElevatedButton(
                                onPressed: null,
                                child: Text('รอการตอบรับ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                ),
                              );
                            }
                          } else {
                            return ElevatedButton(
                              onPressed: () => _joinGroup(context, groupId),
                              child: Text('ขอเข้าร่วม',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[400],
                              ),
                            );
                          }
                        },
                      );
                    }
                  },
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

      // ตรวจสอบว่าผู้ใช้เคยขอเข้าร่วมแล้วหรือไม่
      DocumentSnapshot pendingDoc =
          await groupRef.collection('pending').doc(currentUser.uid).get();
      bool hasPendingRequest = pendingDoc.exists;
      String? pendingStatus = data['request'];

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

      if (!hasPendingRequest && userList.docs.length < groupSize) {
        await groupRef.collection('pending').doc(currentUser.uid).set({
          'userId': currentUser.uid,
          'request': 'waiting',
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ส่งคำขอเข้าร่วมแล้ว กรุณารอการตอบรับ')),
        );
      } else if (hasPendingRequest && (pendingStatus == 'rejected')) {
        await groupRef.collection('pending').doc(currentUser.uid).delete();
        await groupRef.collection('pending').doc(currentUser.uid).set({
          'userId': currentUser.uid,
          'request': 'waiting',
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ส่งคำขอเข้าร่วมใหม่แล้ว กรุณารอการตอบรับ')),
        );
      } else if (hasPendingRequest) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('คุณได้ส่งคำขอเข้าร่วมไปแล้ว')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('กลุ่มเต็มแล้ว')),
        );
      }
    }
  }
}
