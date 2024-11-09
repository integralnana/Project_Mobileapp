import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projectapp/constant.dart';
import 'package:projectapp/model/groupchat.dart';

class ShowChatScreen extends StatefulWidget {
  const ShowChatScreen({super.key});

  @override
  State<ShowChatScreen> createState() => _ShowChatScreenState();
}

class _ShowChatScreenState extends State<ShowChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String currentUserId = '';
  List<GroupChat> groups = [];
  List<GroupChat> filteredGroups = [];
  bool isLoading = true;
  String? errorMessage;
  String? selectedStatus;
  bool isOldestFirst = false;

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

  void filterAndSortGroups() {
    setState(() {
      filteredGroups = List<GroupChat>.from(groups);

      // กรองตามสถานะ
      if (selectedStatus != null) {
        filteredGroups = filteredGroups
            .where((group) => group.groupStatus == selectedStatus)
            .toList();
      }

      // เรียงตามวันที่
      filteredGroups.sort((a, b) {
        if (isOldestFirst) {
          return a.setTime.compareTo(b.setTime);
        } else {
          return b.setTime.compareTo(a.setTime);
        }
      });
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

  Future<void> fetchUserGroups() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      QuerySnapshot groupSnapshot = await _firestore.collection('groups').get();
      List<GroupChat> newGroups = [];

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
            newGroups.add(group);
          } catch (e) {
            print("Error parsing group data: $e");
          }
        }
      }

      setState(() {
        groups = newGroups;
        isLoading = false;
      });
      filterAndSortGroups();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchUserGroups,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey,
            child: Row(
              children: [
                // Status Filter
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
                            child: Text('แสดงทั้งหมด'),
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
                          filterAndSortGroups();
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Sort Toggle
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isOldestFirst = !isOldestFirst;
                    });
                    filterAndSortGroups();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Icon(
                      isOldestFirst ? Icons.arrow_upward : Icons.arrow_downward,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // List View
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
                      final group = filteredGroups[index];
                      return Card(
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
                            // TODO: Navigate to chat detail screen
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
                                    Text(
                                      'ผู้โพสต์: ${group.username}',
                                      style: GoogleFonts.anuphan(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      group.getThaiFormattedTime(),
                                      style: GoogleFonts.anuphan(
                                        color: Colors.grey[600],
                                        fontSize: 12,
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