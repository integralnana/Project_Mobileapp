import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projectapp/constant.dart';
import 'package:projectapp/model/groupchat.dart';
import 'package:projectapp/screen/chatgroup.dart';
import 'package:projectapp/screen/home.dart';

class ShowChatScreen extends StatefulWidget {
  const ShowChatScreen({super.key});

  @override
  State<ShowChatScreen> createState() => _ShowChatScreenState();
}

class _ShowChatScreenState extends State<ShowChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String currentUserId = '';
  List<GroupChatWithRequest> groups = [];
  List<GroupChatWithRequest> filteredGroups = [];
  bool isLoading = true;
  String? errorMessage;
  String? selectedStatus;

  final Set<String> initialVisibleStatuses = {'1', '2', '3'};

  final Map<String, String> statusMap = {
    "1": "กำลังยืนยันการแชร์",
    "2": "กำลังดำเนินการซื้อ",
    "3": "กำลังดำเนินการนัดรับ",
    "4": "นัดรับสำเร็จแล้ว",
  };

  @override
  void initState() {
    super.initState();
    getCurrentUserId();
    fetchUserGroups();
  }

  void filterGroups() {
    setState(() {
      filteredGroups = List<GroupChatWithRequest>.from(groups);

      if (selectedStatus != null) {
        filteredGroups = filteredGroups
            .where((group) => group.group.groupStatus == selectedStatus)
            .toList();
      } else {
        // On initial load or when "show all" is selected,
        // show only groups with status 1, 2, or 3
        filteredGroups = groups
            .where((group) =>
                initialVisibleStatuses.contains(group.group.groupStatus))
            .toList();
      }
    });
  }

  Future<void> getCurrentUserId() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      setState(() {
        currentUserId = currentUser.uid;
      });
    }
  }

  Future<String> getRequestStatus(String groupId) async {
    // เข้าถึงเอกสาร pending ของผู้ใช้ในกลุ่มที่กำหนด
    DocumentSnapshot pendingSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('pending')
        .doc(currentUserId)
        .get();

    // ตรวจสอบว่ามีเอกสารหรือไม่
    if (pendingSnapshot.exists) {
      // ดึงค่าของ request ถ้ามีเอกสาร
      return pendingSnapshot['request'] ?? 'N/A';
    } else {
      return 'N/A'; // กรณีที่ไม่มีข้อมูล request
    }
  }

  Future<void> fetchUserGroups() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      QuerySnapshot groupSnapshot = await _firestore.collection('groups').get();
      List<GroupChatWithRequest> newGroups = [];

      for (var groupDoc in groupSnapshot.docs) {
        String groupId = groupDoc.id;
        DocumentSnapshot userDoc = await _firestore
            .collection('groups')
            .doc(groupId)
            .collection('userlist')
            .doc(currentUserId)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> groupData =
              groupDoc.data() as Map<String, dynamic>;
          groupData['groupId'] = groupId;

          try {
            GroupChat group = GroupChat.fromJson(groupData);
            String requestStatus = await getRequestStatus(groupId);

            newGroups.add(GroupChatWithRequest(
              group: group,
              requestStatus: requestStatus,
            ));
          } catch (e) {
            print("Error parsing group data: $e");
          }
        }
      }

      setState(() {
        groups = newGroups;
        isLoading = false;
      });
      filterGroups();
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'เกิดข้อผิดพลาดในการโหลดข้อมูล กรุณาลองใหม่อีกครั้ง';
      });
      print("Error fetching user groups: $e");
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "1":
        return Colors.orange;
      case "2":
        return Colors.blue;
      case "3":
        return Colors.purple;
      case "4":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarColor,
        title: Text(
          'แชทกลุ่ม',
          style: GoogleFonts.anuphan(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (context) => HomeScreen()), // หน้าหลักของคุณ
              (Route<dynamic> route) => false, // ลบ stack ของหน้าก่อนหน้า
            );
          },
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.appBarColor,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedStatus,
                        hint: Text(
                          'กรองตามสถานะ',
                          style: GoogleFonts.anuphan(),
                        ),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('สถานะกลุ่ม : แสดงทั้งหมด'),
                          ),
                          ...statusMap.entries.map((entry) {
                            return DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.value),
                            );
                          }).toList(),
                        ],
                        onChanged: (String? value) {
                          setState(() {
                            selectedStatus = value;
                          });
                          filterGroups();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchUserGroups,
              child: Builder(
                builder: (context) {
                  if (isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            errorMessage!,
                            style: GoogleFonts.anuphan(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: fetchUserGroups,
                            child: Text(
                              'ลองใหม่',
                              style: GoogleFonts.anuphan(),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (filteredGroups.isEmpty) {
                    return Center(
                      child: Text(
                        'ไม่พบแชทกลุ่ม',
                        style: GoogleFonts.anuphan(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: filteredGroups.length,
                    itemBuilder: (context, index) {
                      final groupWithRequest = filteredGroups[index];
                      final group = groupWithRequest.group;

                      String groupStatusText;
                      if (group.groupGenre == 1) {
                        groupStatusText = "แชร์ซื้อสินค้า";
                      } else if (group.groupGenre == 2) {
                        groupStatusText = "สินค้าลดราคา";
                      } else {
                        groupStatusText = "ไม่ทราบสถานะ";
                      }

                      Color getRequestStatusColor(String groupStatusText) {
                        switch (groupStatusText) {
                          case '1':
                            return AppTheme.cardColor;
                          case '2':
                            return AppTheme.cardDiscColor;
                          default:
                            return Colors.white;
                        }
                      }

                      return Card(
                        color: getRequestStatusColor(groupStatusText),
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatGroupScreen(
                                  groupId: group.groupId,
                                  currentUserId: currentUserId,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        group.groupName,
                                        style: GoogleFonts.anuphan(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: getStatusColor(group.groupStatus)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color:
                                              getStatusColor(group.groupStatus),
                                        ),
                                      ),
                                      child: Text(
                                        statusMap[group.groupStatus] ??
                                            'ไม่ทราบสถานะ',
                                        style: GoogleFonts.anuphan(
                                          color:
                                              getStatusColor(group.groupStatus),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'ผู้โพสต์: ${group.userId == currentUserId ? 'คุณ' : group.username}',
                                        style: GoogleFonts.anuphan(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(),
                                      ),
                                      child: Text(
                                        groupStatusText,
                                        style: GoogleFonts.anuphan(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      // เพิ่ม Expanded เพื่อควบคุมพื้นที่
                                      child: Text(
                                        'เวลานัดรับ: ${group.getThaiFormattedDate()}',
                                        style: GoogleFonts.anuphan(
                                          color: Colors.grey[600],
                                        ),
                                        overflow: TextOverflow
                                            .ellipsis, // เพิ่ม ... เมื่อข้อความยาวเกิน
                                        maxLines:
                                            1, // จำกัดให้แสดงเพียงบรรทัดเดียว
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GroupChatWithRequest {
  final GroupChat group;
  final String requestStatus;

  GroupChatWithRequest({
    required this.group,
    required this.requestStatus,
  });
}
