import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projectapp/constant.dart';

class NotiScreen extends StatefulWidget {
  @override
  State<NotiScreen> createState() => _NotiScreenState();
}

class _NotiScreenState extends State<NotiScreen> {
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

  Future<void> _handleRequest(
    BuildContext context,
    String groupId,
    String userId,
    String action,
  ) async {
    final groupRef =
        FirebaseFirestore.instance.collection('groups').doc(groupId);

    // Update request status
    await groupRef.collection('pending').doc(userId).update({
      'request': action == 'approve' ? 'approved' : 'rejected',
    });

    // If rejected, delete pending request
    if (action == 'reject') {
      await groupRef.collection('pending').doc(userId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ปฏิเสธคำขอเรียบร้อย',
          ),
        ),
      );
    }

    // If approved, add user to userlist
    if (action == 'approve') {
      // Fetch user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      // Add to userlist
      await groupRef.collection('userlist').doc(userId).set({
        'userId': userId,
        'username': userDoc.data()?['username'] ?? 'Unknown User',
        'imageUrl': userDoc.data()?['imageUrl'], // Add imageUrl field
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'อนุมัติคำขอเรียบร้อย',
          ),
        ),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          action == 'approve' ? 'อนุมัติคำขอเรียบร้อย' : 'ปฏิเสธคำขอเรียบร้อย',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarColor,
        title: Text('การแจ้งเตือน'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .where('userId', isEqualTo: currentUser?.uid)
            .snapshots(),
        builder: (context, groupSnapshot) {
          if (!groupSnapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: groupSnapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final groupDoc = groupSnapshot.data!.docs[index];
              final groupId = groupDoc.id;

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('groups')
                    .doc(groupId)
                    .collection('pending')
                    .where('request', isEqualTo: 'waiting')
                    .snapshots(),
                builder: (context, pendingSnapshot) {
                  if (!pendingSnapshot.hasData) {
                    return SizedBox();
                  }

                  return Column(
                    children: pendingSnapshot.data!.docs.map((pendingDoc) {
                      final userId = pendingDoc.id;
                      final timestamp = pendingDoc['timestamp'] as Timestamp;

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .get(),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData) {
                            return SizedBox();
                          }

                          final username =
                              userSnapshot.data?['username'] ?? 'Unknown User';
                          final userProfileImageUrl = userSnapshot
                              .data?['imageUrl']; // Get user profile image URL

                          // Calculate time since notification
                          final now = DateTime.now();
                          final timeSinceNotification =
                              now.difference(timestamp.toDate());

                          String timeSinceNotificationText;
                          if (timeSinceNotification.inDays >= 1) {
                            timeSinceNotificationText =
                                '${timeSinceNotification.inDays} วันที่แล้ว';
                          } else if (timeSinceNotification.inHours >= 1) {
                            timeSinceNotificationText =
                                '${timeSinceNotification.inHours} ชั่วโมงที่แล้ว';
                          } else {
                            timeSinceNotificationText =
                                '${timeSinceNotification.inMinutes} นาทีที่แล้ว';
                          }

                          return Card(
                            margin: EdgeInsets.all(8),
                            child: Container(
                              padding:
                                  EdgeInsets.only(top: 20, left: 20, right: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Text(
                                              '${groupDoc['groupName']} : ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16),
                                            ),
                                            Text(
                                              ' คุณมีคำขอเข้าร่วม',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '$timeSinceNotificationText',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundImage: userProfileImageUrl !=
                                                null
                                            ? NetworkImage(userProfileImageUrl)
                                            : AssetImage(
                                                    'assets/images/default_user_image.png')
                                                as ImageProvider,
                                        radius: 25,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        username,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                            maxWidth:
                                                150), // Set the maximum width of the button container
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextButton(
                                              child: Text(
                                                "ยอมรับ",
                                                style: TextStyle(
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16),
                                              ),
                                              onPressed: () => _handleRequest(
                                                context,
                                                groupId,
                                                userId,
                                                'approve',
                                              ),
                                            ),
                                            TextButton(
                                              child: Text("ปฏิเสธ",
                                                  style: TextStyle(
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16)),
                                              onPressed: () => _handleRequest(
                                                context,
                                                groupId,
                                                userId,
                                                'reject',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
