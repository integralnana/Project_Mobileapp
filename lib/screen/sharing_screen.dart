import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:projectapp/constant.dart';
import 'package:projectapp/model/groupchat.dart';
import 'package:projectapp/screen/chatgroup.dart';
import 'package:projectapp/screen/createpost.dart';
import 'package:projectapp/screen/profile.dart';

class SharingScreen extends StatefulWidget {
  @override
  State<SharingScreen> createState() => _SharingScreenState();
}

class _SharingScreenState extends State<SharingScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;

  String? selectedCategory;
  int? selectedPaymentType;

  Future<List<Map<String, dynamic>>> getGroupsWithUserStatus() async {
    DateTime now = DateTime.now();
    Timestamp currentTimestamp = Timestamp.fromDate(now);

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('groups')
        .where('groupStatus', whereNotIn: [2, 3, 4])
        .where('groupGenre', isEqualTo: 1)
        .where('setTime', isGreaterThanOrEqualTo: currentTimestamp)
        .orderBy('setTime');

    if (selectedCategory != null) {
      query = query.where('groupCate', isEqualTo: selectedCategory);
    }

    if (selectedPaymentType != null) {
      query = query.where('groupType', isEqualTo: selectedPaymentType);
    }

    QuerySnapshot groupSnapshot = await query.get();
    List<Map<String, dynamic>> groups = [];

    for (var doc in groupSnapshot.docs) {
      Map<String, dynamic> groupData = doc.data() as Map<String, dynamic>;
      String creatorId = groupData['userId'];

      // เพิ่ม document ID เข้าไปในข้อมูล
      groupData['id'] = doc.id;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(creatorId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        groupData['creatorStatus'] = userData['status'];
      } else {
        groupData['creatorStatus'] = '1';
      }

      groups.add(groupData);
    }

    groups.sort((a, b) {
      if (a['creatorStatus'] == '2' && b['creatorStatus'] != '2') {
        return -1;
      } else if (a['creatorStatus'] != '2' && b['creatorStatus'] == '2') {
        return 1;
      } else {
        Timestamp timeA = a['setTime'];
        Timestamp timeB = b['setTime'];
        return timeA.compareTo(timeB);
      }
    });

    return groups;
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

  void _navigateToProfileScreen(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'หน้าแชร์ซื้อสินค้า',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: getGroupsWithUserStatus(),
              builder: (context,
                  AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                if (snapshot.hasError) {
                  print('Error: ${snapshot.error}');
                  return Center(
                      child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                  children: snapshot.data!.map((data) {
                    return FutureBuilder<List<dynamic>>(
                      future: Future.wait([
                        _getUserProfileImage(data['userId']),
                        _getUserListCount(data['id']),
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
                          data['id'],
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

    return GestureDetector(
      onTap: () {
        showPostDetailModal(
          context,
          data,
          profileImageUrl,
          currentMemberCount,
          groupId,
          formattedDateTime,
        );
      },
      child: Card(
        color: AppTheme.cardColor,
        margin: EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: GestureDetector(
                onTap: () => _navigateToProfileScreen(data['userId']),
                child: CircleAvatar(
                  backgroundImage: profileImageUrl != null
                      ? NetworkImage(profileImageUrl)
                      : AssetImage('assets/images/default_user_image.png')
                          as ImageProvider,
                  radius: 20,
                ),
              ),
              title: GestureDetector(
                  onTap: () => _navigateToProfileScreen(data['userId']),
                  child: Row(
                    children: [
                      Text(username,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(
                        width: 4,
                      ),
                      if (data['creatorStatus'] == '2')
                        Icon(
                          Icons.diamond,
                          color: Colors.purple,
                        ),
                    ],
                  )),
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
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                      style:
                          TextStyle(color: Colors.blue.shade800, fontSize: 14),
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
                      style:
                          TextStyle(color: Colors.blue.shade800, fontSize: 14),
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
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              } else {
                                return ElevatedButton(
                                  onPressed: null,
                                  child: Text('รอการตอบรับ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
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
      ),
    );
  }

  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // ตรวจสอบว่า location services เปิดอยู่หรือไม่
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // แสดง dialog แจ้งเตือนให้เปิด location service
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Location Service ปิดอยู่',
              style: GoogleFonts.anuphan(),
            ),
            content: Text(
              'กรุณาเปิด Location Service เพื่อใช้งานแผนที่',
              style: GoogleFonts.anuphan(),
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
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'Permission ถูกปฏิเสธ',
                style: GoogleFonts.anuphan(),
              ),
              content: Text(
                'ไม่สามารถเข้าถึงตำแหน่งของคุณได้',
                style: GoogleFonts.anuphan(),
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
        return false;
      }
    }

    return true;
  }

  Future<void> _showLocationDialog(
      BuildContext context, double latitude, double longitude) async {
    // เช็ค permission ก่อน
    bool hasPermission = await _checkLocationPermission();
    if (!hasPermission) {
      return; // ถ้าไม่ได้รับ permission ให้ return ออกไป
    }

    // ถ้าได้รับ permission แล้วค่อยแสดง dialog
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
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              mapToolbarEnabled: true,
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

      // ตรวจสอบว่าผู้ใช้มีคำขอที่รออยู่หรือไม่
      DocumentSnapshot pendingDoc =
          await groupRef.collection('pending').doc(currentUser.uid).get();
      bool hasPendingRequest = pendingDoc.exists;

      // ถ้าเป็นสมาชิกแล้ว ให้ไปที่หน้าแชท
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

      // ตรวจสอบจำนวนสมาชิกในกลุ่ม
      if (userList.docs.length >= groupSize) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('กลุ่มเต็มแล้ว')),
        );
        return;
      }

      // กรณีที่ยังไม่เคยส่งคำขอ หรือเคยถูกปฏิเสธ
      if (!hasPendingRequest ||
          (pendingDoc.exists && pendingDoc.get('request') == 'rejected')) {
        await groupRef.collection('pending').doc(currentUser.uid).set({
          'userId': currentUser.uid,
          'request': 'waiting',
          'timestamp': FieldValue.serverTimestamp(),
        });

        String message = !hasPendingRequest
            ? 'ส่งคำขอเข้าร่วมแล้ว กรุณารอการตอบรับ'
            : 'ส่งคำขอเข้าร่วมใหม่แล้ว กรุณารอการตอบรับ';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } else {
        // กรณีที่มีคำขอที่รออยู่แล้ว
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('คุณมีคำขอที่รออยู่แล้ว กรุณารอการตอบรับ')),
        );
      }
    }
  }

  void showPostDetailModal(
    BuildContext context,
    Map<String, dynamic> data,
    String? profileImageUrl,
    int currentMemberCount,
    String groupId,
    String formattedDateTime,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // เนื้อหา
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            child: GestureDetector(
                              onTap: () =>
                                  _navigateToProfileScreen(data['userId']),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: profileImageUrl != null
                                        ? NetworkImage(profileImageUrl)
                                        : AssetImage(
                                                'assets/images/default_user_image.png')
                                            as ImageProvider,
                                    radius: 30,
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              data['username'] ??
                                                  'Unknown User',
                                              style: GoogleFonts.anuphan(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(
                                              width: 4,
                                            ),
                                            if (data['creatorStatus'] == '2')
                                              Icon(
                                                Icons.diamond,
                                                color: Colors.purple,
                                              ),
                                          ],
                                        ),
                                        SizedBox(height: 4),
                                        Icon(Icons.calendar_month),
                                        SizedBox(width: 4),
                                        Text(formattedDateTime),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // รูปภาพกลุ่มแบบเต็ม
                          Container(
                            width: double.infinity,
                            height: 300,
                            child: Image.network(
                              data['groupImage'] ?? '',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/default_group_image.png',
                                  fit: BoxFit
                                      .contain, // เปลี่ยนตรงนี้ด้วยเพื่อให้สอดคล้องกัน
                                );
                              },
                            ),
                          ),

                          // รายละเอียดกลุ่ม
                          Container(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        data['groupName'] ?? 'ชื่อกลุ่ม',
                                        style: GoogleFonts.anuphan(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '$currentMemberCount/${data['groupSize']} คน',
                                        style: TextStyle(
                                          color: Colors.red.shade800,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        data['groupCate'] ?? 'ไม่มีระบุ',
                                        style: TextStyle(
                                            color: Colors.blue.shade800),
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        data['groupType'] == 1
                                            ? 'โอนก่อน'
                                            : 'จ่ายหลังนัดรับ',
                                        style: TextStyle(
                                            color: Colors.blue.shade800),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 24),
                                Text(
                                  'รายละเอียด',
                                  style: GoogleFonts.anuphan(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  data['groupDesc'] ?? 'ไม่มีคำอธิบาย',
                                  style: GoogleFonts.anuphan(
                                    fontSize: 16,
                                    color: Colors.grey[800],
                                  ),
                                ),

                                // ปุ่มดูสถานที่และเข้าร่วมกลุ่ม
                                SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        _showLocationDialog(
                                            context,
                                            data['latitude'] ?? 0.0,
                                            data['longitude'] ?? 0.0);
                                      },
                                      icon: Icon(Icons.location_on, size: 18),
                                      label: Text('ดูสถานที่นัดรับ',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red),
                                    ),
                                    StreamBuilder<DocumentSnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('groups')
                                          .doc(groupId)
                                          .collection('userlist')
                                          .doc(currentUser?.uid)
                                          .snapshots(),
                                      builder: (context, userSnapshot) {
                                        if (userSnapshot.hasData &&
                                            userSnapshot.data!.exists) {
                                          return ElevatedButton(
                                            onPressed: () =>
                                                _joinGroup(context, groupId),
                                            child: Text('เข้าร่วมแชร์',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue),
                                          );
                                        } else {
                                          return StreamBuilder<
                                              DocumentSnapshot>(
                                            stream: FirebaseFirestore.instance
                                                .collection('groups')
                                                .doc(groupId)
                                                .collection('pending')
                                                .doc(currentUser?.uid)
                                                .snapshots(),
                                            builder:
                                                (context, pendingSnapshot) {
                                              if (pendingSnapshot.hasData &&
                                                  pendingSnapshot
                                                      .data!.exists) {
                                                var pendingStatus =
                                                    pendingSnapshot
                                                        .data!['request'];
                                                if (pendingStatus ==
                                                    'rejected') {
                                                  return ElevatedButton(
                                                    onPressed: () => _joinGroup(
                                                        context, groupId),
                                                    child: Text('ขอเข้าร่วม',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.orange,
                                                    ),
                                                  );
                                                } else {
                                                  return ElevatedButton(
                                                    onPressed: null,
                                                    child: Text('รอการตอบรับ',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.grey,
                                                    ),
                                                  );
                                                }
                                              } else {
                                                return ElevatedButton(
                                                  onPressed: () => _joinGroup(
                                                      context, groupId),
                                                  child: Text('ขอเข้าร่วม',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.orange[400],
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
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
