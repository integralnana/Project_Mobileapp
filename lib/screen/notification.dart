import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projectapp/constant.dart';
import 'package:projectapp/screen/profile.dart';

class NotiScreen extends StatefulWidget {
  const NotiScreen({Key? key}) : super(key: key);

  @override
  State<NotiScreen> createState() => _NotiScreenState();
}

class _NotiScreenState extends State<NotiScreen> with TickerProviderStateMixin {
  final currentUser = FirebaseAuth.instance.currentUser;
  final _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

  // แยกส่วนการแสดงผลเวลาออกมาเป็นฟังก์ชันที่แยกต่างหาก
  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays >= 1) {
      return '${difference.inDays} วันที่แล้ว';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else {
      return '${difference.inMinutes} นาทีที่แล้ว';
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // แยกการจัดการคำขอออกมาให้ชัดเจน
  Future<void> _handleRequest(
    BuildContext context,
    String groupId,
    String userId,
    String action,
  ) async {
    try {
      final groupRef = _firestore.collection('groups').doc(groupId);
      final pendingRef = groupRef.collection('pending').doc(userId);

      final userRef = _firestore.collection('users').doc(userId);

      if (action == 'approve') {
        await _handleApproval(context, groupRef, userId, userRef, pendingRef);
      } else {
        await _handleRejection(context, pendingRef, userRef, userId, groupRef);
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Error: $e');
    }
  }

  Future<void> _handleApproval(
    BuildContext context,
    DocumentReference groupRef,
    String userId,
    DocumentReference userRef,
    DocumentReference pendingRef,
  ) async {
    // Check group size
    final groupDoc = await groupRef.get();
    final groupData = groupDoc.data() as Map<String, dynamic>?;
    final int groupSize = groupData?['groupSize'];

    final userlistSnapshot = await groupRef.collection('userlist').get();
    if (userlistSnapshot.docs.length >= groupSize) {
      _showSnackBar(context, 'Group is full');
      return;
    }

    // Get user data and add to group
    final userData = (await userRef.get()).data() as Map<String, dynamic>?;

    await groupRef.collection('userlist').doc(userId).set({
      'userId': userId,
      'username': userData?['username'] ?? 'Unknown User',
      'imageUrl': userData?['imageUrl'],
      'joinedAt': FieldValue.serverTimestamp(),
    });

    await groupRef.collection('pending').doc(userId).update({
      'request': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
    });

    // Store the approved request in the user's pendingnoti subcollection
    await userRef.collection('pendingnoti').doc(userId).set({
      'groupName': '${groupData?['groupName']}',
      'pendingcom': 'คำขอของคุณถูกยอมรับแล้ว',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await groupRef.collection('messages').add({
      'type': 'notification',
      'text': '${userData?['username']} ได้เข้าร่วมกลุ่มแล้ว',
      'senderId': 'server',
      'setTime': FieldValue.serverTimestamp(),
    });

    _showSnackBar(context, 'Request approved');
  }

  Future<void> _handleRejection(
    BuildContext context,
    DocumentReference pendingRef,
    DocumentReference userRef,
    String userId,
    DocumentReference groupRef,
  ) async {
    final groupDoc = await groupRef.get();
    final groupData = groupDoc.data() as Map<String, dynamic>?;
    try {
      _showSnackBar(context, 'Request rejected');
      await pendingRef.update({
        'request': 'rejected',
      });

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('pendingnoti')
          .doc(userId)
          .set({
        'groupName': '${groupData?['groupName']}',
        'pendingcom': 'คำขอของคุณถูกปฏิเสธ',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _showErrorSnackBar(context, 'Error rejecting request: $e');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.1,
          left: 16,
          right: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.1,
          left: 16,
          right: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildJoinRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('groups')
          .where('userId', isEqualTo: currentUser?.uid)
          .snapshots(),
      builder: (context, groupSnapshot) {
        if (!groupSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (groupSnapshot.data!.docs.isEmpty) {
          return const Center(child: Text('ไม่มีคำขอเข้าร่วมกลุ่ม'));
        }

        return ListView.builder(
          itemCount: groupSnapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final groupDoc = groupSnapshot.data!.docs[index];
            return StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('groups')
                  .doc(groupDoc.id)
                  .collection('pending')
                  .where('request', isEqualTo: 'waiting')
                  .snapshots(),
              builder: (context, pendingSnapshot) {
                if (!pendingSnapshot.hasData ||
                    pendingSnapshot.data!.docs.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Column(
                  children: pendingSnapshot.data!.docs
                      .map((pendingDoc) =>
                          _buildRequestCard(context, groupDoc, pendingDoc))
                      .toList(),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(currentUser?.uid)
          .collection('pendingnoti')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('ไม่มีการแจ้งเตือน'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Text(
                  doc['groupName'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc['pendingcom']),
                    Text(
                      _getTimeAgo((doc['timestamp'] as Timestamp).toDate()),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () async {
                    await _firestore
                        .collection('users')
                        .doc(currentUser?.uid)
                        .collection('pendingnoti')
                        .doc(doc.id)
                        .delete();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ลบการแจ้งเตือนแล้ว'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    QueryDocumentSnapshot groupDoc,
    QueryDocumentSnapshot pendingDoc,
  ) {
    final userId = pendingDoc.id;
    final timestamp = pendingDoc['timestamp'] as Timestamp;
    final groupId = groupDoc.id;

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(userId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const SizedBox.shrink();
        }

        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final username = userData?['username'] ?? 'Unknown User';
        final userProfileImageUrl = userData?['imageUrl'];

        return Card(
          margin: const EdgeInsets.all(8),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRequestHeader(groupDoc, timestamp),
                const SizedBox(height: 12),
                _buildUserInfo(context, username, userProfileImageUrl,
                    userId), // ส่ง context และ userId เพิ่มเติม
                const SizedBox(height: 12),
                _buildActionButtons(context, groupId, userId),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPendingNotificationList() {
    // Build the list of pending notifications
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(currentUser?.uid)
          .collection('pendingnoti')
          .snapshots(),
      builder: (context, pendingSnapshot) {
        if (!pendingSnapshot.hasData || pendingSnapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: pendingSnapshot.data!.docs
              .map((pendingDoc) => Card(
                    margin: const EdgeInsets.all(8),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(pendingDoc['groupName']),
                              Text(pendingDoc['pendingcom']),
                            ],
                          ),
                          TextButton(
                            onPressed: () async {
                              await _firestore
                                  .collection('users')
                                  .doc(currentUser?.uid)
                                  .collection('pendingnoti')
                                  .doc(pendingDoc.id)
                                  .delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Pending notification deleted'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildRequestHeader(
    QueryDocumentSnapshot groupDoc,
    Timestamp timestamp,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black, fontSize: 16),
              children: [
                TextSpan(
                  text: '${groupDoc['groupName']} : ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: 'คุณมีคำขอเข้าร่วม'),
              ],
            ),
          ),
        ),
        Text(
          _getTimeAgo(timestamp.toDate()),
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildUserInfo(BuildContext context, String username,
      String? userProfileImageUrl, String userId) {
    return Row(
      children: [
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(userId: userId),
              ),
            );
          },
          child: CircleAvatar(
            backgroundImage: userProfileImageUrl != null
                ? NetworkImage(userProfileImageUrl)
                : const AssetImage('assets/images/default_user_image.png')
                    as ImageProvider,
            radius: 25,
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(userId: userId),
              ),
            );
          },
          child: Text(
            username,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              decoration: TextDecoration
                  .underline, // เพิ่มขีดเส้นใต้เพื่อแสดงว่าสามารถกดได้
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    String groupId,
    String userId,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () => _handleRequest(context, groupId, userId, 'approve'),
          child: const Text(
            'ยอมรับ',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 16),
        TextButton(
          onPressed: () => _handleRequest(context, groupId, userId, 'reject'),
          child: const Text(
            'ปฏิเสธ',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Center(child: Text('กรุณาเข้าสู่ระบบ'));
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarColor,
        title: const Text(
          'การแจ้งเตือน',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.group_add),
              text: 'คำขอเข้าร่วม',
            ),
            Tab(
              icon: Icon(Icons.notifications),
              text: 'การแจ้งเตือน',
            ),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildJoinRequestsTab(),
          _buildNotificationsTab(),
        ],
      ),
    );
  }
}
