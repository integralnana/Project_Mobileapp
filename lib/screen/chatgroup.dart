import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:projectapp/constant.dart';
import 'package:projectapp/model/groupchat.dart';
import 'package:projectapp/screen/profile.dart';
import 'package:projectapp/screen/showchat.dart';

class ChatGroupScreen extends StatefulWidget {
  final String groupId, currentUserId;
  ChatGroupScreen({required this.groupId, required this.currentUserId});
  @override
  _ChatGroupScreenState createState() => _ChatGroupScreenState();
}

class _ChatGroupScreenState extends State<ChatGroupScreen> {
  final TextEditingController _messageController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  String? groupName, groupStatus, groupLeaderId;
  double? latitude, longitude;
  bool isGroupLeader = false, hasConfirmedPurchase = false;
  int? groupSize;
  File? _selectedImage;
  String? currentusername;

  @override
  void initState() {
    super.initState();
    _initializeGroup();
  }

  Future<void> _initializeGroup() async {
    await Future.wait(
        [_fetchGroupDetails(), _joinGroup(), _checkUserConfirmation()]);
  }

  Future<void> _fetchGroupDetails() async {
    var doc = await _firestore.collection('groups').doc(widget.groupId).get();
    if (doc.exists) {
      var data = doc.data()!;
      setState(() {
        groupName = data['groupName'];
        groupStatus = data['groupStatus'].toString();
        latitude = data['latitude'];
        longitude = data['longitude'];
        groupLeaderId = data['userId'];
        groupSize = data['groupSize'] ?? 0;
        isGroupLeader = groupLeaderId == widget.currentUserId;
      });
    }
    final memberCount = (await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('userlist')
            .get())
        .docs
        .length;
    if (groupSize != memberCount && groupStatus != '4') {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .update({'groupStatus': '1'});

      var snapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('confirmations')
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }
  }

  Future<void> _handleImageMessage() async {
    if (_selectedImage == null) {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null)
        setState(() => _selectedImage = File(pickedFile.path));
      return;
    }

    try {
      var storageRef = FirebaseStorage.instance.ref().child(
          'groupFiles/${widget.groupId}/${widget.currentUserId}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await storageRef.putFile(_selectedImage!);
      final imageUrl = await storageRef.getDownloadURL();

      await _sendMessage(type: 'image', imageUrl: imageUrl);
      setState(() => _selectedImage = null);
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  Future<void> _handleConfirmation(bool confirm) async {
    if (!confirm && !hasConfirmedPurchase) return;

    var confirmationRef = _firestore
        .collection('groups')
        .doc(widget.groupId)
        .collection('confirmations')
        .doc(widget.currentUserId);

    if (confirm) {
      await confirmationRef.set({'confirmedAt': FieldValue.serverTimestamp()});
      setState(() => hasConfirmedPurchase = true);
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('ยืนยันการยกเลิก'),
          content: Text('คุณต้องการยกเลิกการยืนยันการซื้อหรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('ไม่'),
            ),
            TextButton(
              onPressed: () async {
                await confirmationRef.delete();
                setState(() => hasConfirmedPurchase = false);
                Navigator.pop(context);
                _showSnackBar('ยกเลิกการยืนยันการซื้อแล้ว');
              },
              child: Text('ใช่'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _sendMessage({String type = 'text', String? imageUrl}) async {
    if (type == 'text' && _messageController.text.isEmpty) return;

    await _firestore
        .collection('groups')
        .doc(widget.groupId)
        .collection('messages')
        .add({
      'type': type,
      if (type == 'text') 'text': _messageController.text,
      if (type == 'image') 'imageUrl': imageUrl,
      'senderId': widget.currentUserId,
      'setTime': FieldValue.serverTimestamp(),
    });

    if (type == 'text') _messageController.clear();
  }

  Future<void> _joinGroup() async {
    var userDoc = await _firestore
        .collection('groups')
        .doc(widget.groupId)
        .collection('userlist')
        .doc(widget.currentUserId)
        .get();

    if (!userDoc.exists) {
      await userDoc.reference.set({'joinedAt': FieldValue.serverTimestamp()});
    }
  }

  Future<void> _showReviewDialog(String userId) async {
    if (userId == widget.currentUserId) return;

    final reviewDoc = await FirebaseFirestore.instance
        .collection('users/${userId}/reviews')
        .where('userId', isEqualTo: widget.currentUserId)
        .get();

    if (reviewDoc.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('คุณได้รีวิวผู้ใช้นี้ไปแล้ว', style: GoogleFonts.anuphan()),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    final userData =
        (await FirebaseFirestore.instance.collection('users').doc(userId).get())
            .data();
    if (userData == null) return;

    int selectedStar = 0;
    String comment = '';

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('รีวิวสมาชิก',
              style: GoogleFonts.anuphan(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildUserProfile({
                  'username': userData['username'] ?? 'ไม่มีชื่อผู้ใช้',
                  'imageUrl': userData['imageUrl'] ?? '',
                  'fullName':
                      '${userData['fname'] ?? ''} ${userData['lname'] ?? ''}'
                          .trim(),
                }),
                const SizedBox(height: 20),
                Text('ให้คะแนนสมาชิก',
                    style: GoogleFonts.anuphan(fontSize: 16)),
                const SizedBox(height: 8),
                _buildStarRating(selectedStar,
                    (rating) => setState(() => selectedStar = rating)),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'เขียนคอมเมนต์',
                    hintStyle: GoogleFonts.anuphan(),
                    border: const OutlineInputBorder(),
                    filled: true,
                  ),
                  maxLines: 3,
                  onChanged: (value) => comment = value,
                  style: GoogleFonts.anuphan(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('ยกเลิก',
                  style: GoogleFonts.anuphan(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: selectedStar > 0
                  ? () async {
                      await _submitReview(userId, selectedStar, comment);
                      Navigator.pop(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                disabledBackgroundColor: Colors.grey,
              ),
              child: Text('ยืนยัน',
                  style: GoogleFonts.anuphan(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfile(Map<String, dynamic> userInfo) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: userInfo['imageUrl'].isNotEmpty
                ? NetworkImage(userInfo['imageUrl'])
                : null,
            child:
                userInfo['imageUrl'].isEmpty ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userInfo['username'],
                    style: GoogleFonts.anuphan(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    )),
                Text(userInfo['fullName'],
                    style: GoogleFonts.anuphan(
                      color: Colors.grey[600],
                      fontSize: 14,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(int selectedStar, Function(int) onRatingSelected) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (index) => IconButton(
          icon: Icon(
            index < selectedStar ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 32,
          ),
          onPressed: () => onRatingSelected(index + 1),
        ),
      ),
    );
  }

  Future<void> _submitReview(String userId, int star, String comment) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'point': FieldValue.increment(star)});
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('reviews')
        .doc(widget.currentUserId)
        .set({
      'star': star,
      'userId': widget.currentUserId,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('รีวิวสมาชิกเรียบร้อยแล้ว')));
  }

  Future<void> _kickMember(String userId) async {
    if (!isGroupLeader ||
        groupStatus == '3' ||
        userId == widget.currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(!isGroupLeader
                ? 'เฉพาะหัวหน้ากลุ่มเท่านั้นที่สามารถเตะสมาชิกออกได้'
                : groupStatus == '3'
                    ? 'ไม่สามารถเตะสมาชิกออกได้ในช่วงดำเนินการนัดรับ'
                    : 'คุณไม่สามารถเตะตัวเองออกจากกลุ่มได้')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('ยืนยันการเตะผู้ใช้'),
        content: Text('คุณต้องการเตะผู้ใช้นี้หรือไม่?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ยกเลิก')),
          TextButton(
            onPressed: () async {
              await _removeMemberFromGroup(userId);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('เตะสมาชิกออกจากกลุ่มเรียบร้อย')));
            },
            child: Text('ยืนยัน'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeMemberFromGroup(String userId) async {
    var groupDoc =
        FirebaseFirestore.instance.collection('groups').doc(widget.groupId);
    await groupDoc.collection('pending').doc(userId).delete();
    await groupDoc.collection('userlist').doc(userId).delete();

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    currentusername = userDoc.data()?['username'];

    await _firestore
        .collection('groups')
        .doc(widget.groupId)
        .collection('messages')
        .add({
      'type': 'notification',
      'text': '$currentusername ถูกเตะออกจากกลุ่ม',
      'senderId': 'server',
      'setTime': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _selectImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null)
      setState(() => _selectedImage = File(pickedFile.path));
  }

  Future<void> _sendImageMessage() async {
    if (_selectedImage != null) {
      try {
        var storageRef = FirebaseStorage.instance.ref().child(
            'groupFiles/${widget.groupId}/${widget.currentUserId}/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await storageRef.putFile(_selectedImage!);
        final imageUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('messages')
            .add({
          'type': 'image',
          'imageUrl': imageUrl,
          'senderId': widget.currentUserId,
          'setTime': FieldValue.serverTimestamp(),
        });

        setState(() => _selectedImage = null);
      } catch (e) {
        print('Error uploading image: $e');
      }
    }
  }

  void _cancelSelectedImage() => setState(() => _selectedImage = null);

  Future<void> _checkUserConfirmation() async {
    var doc = await _firestore
        .collection('groups')
        .doc(widget.groupId)
        .collection('confirmations')
        .doc(widget.currentUserId)
        .get();

    setState(() => hasConfirmedPurchase = doc.exists);
  }

  void _showuserlist() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: double.maxFinite,
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'รายชื่อสมาชิกในกลุ่ม',
                      style: GoogleFonts.anuphan(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('groups')
                          .doc(widget.groupId)
                          .collection('userlist')
                          .snapshots(),
                      builder: (context, userlistSnapshot) {
                        if (userlistSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }

                        if (!userlistSnapshot.hasData ||
                            userlistSnapshot.data!.docs.isEmpty) {
                          return Text('0/$groupSize');
                        }

                        return Text(
                          '${userlistSnapshot.data!.docs.length}/$groupSize',
                          style: GoogleFonts.anuphan(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  constraints: BoxConstraints(maxHeight: 300),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('groups')
                        .doc(widget.groupId)
                        .collection('userlist')
                        .snapshots(),
                    builder: (context, userlistSnapshot) {
                      if (userlistSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (!userlistSnapshot.hasData ||
                          userlistSnapshot.data!.docs.isEmpty) {
                        return Center(
                            child: Text('ไม่มีสมาชิกในกลุ่มนี้',
                                style: GoogleFonts.anuphan()));
                      }

                      // Separate leader and members
                      List<QueryDocumentSnapshot> members =
                          userlistSnapshot.data!.docs;
                      List<QueryDocumentSnapshot> normalMembers = [];
                      QueryDocumentSnapshot? leader;

                      for (var doc in members) {
                        if (doc.id == groupLeaderId) {
                          leader = doc;
                        } else {
                          normalMembers.add(doc);
                        }
                      }

                      return ListView(
                        shrinkWrap: true,
                        children: [
                          // Show leader first
                          if (leader != null)
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(leader.id)
                                  .get(),
                              builder: _buildUserListTile,
                            ),
                          // Divider after leader
                          if (leader != null) Divider(thickness: 2),
                          // Show other members
                          ...normalMembers
                              .map((doc) => FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(doc.id)
                                        .get(),
                                    builder: _buildUserListTile,
                                  )),
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('ปิด', style: GoogleFonts.anuphan()),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _leaveGroup() async {
    if (groupStatus == '3') {
      _showAlert(
        'ไม่สามารถออกจากกลุ่มได้',
        'ไม่สามารถออกจากกลุ่มในช่วงดำเนินการนัดรับได้',
      );
      return;
    }

    if (isGroupLeader) {
      final memberCount = (await FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.groupId)
              .collection('userlist')
              .get())
          .docs
          .length;

      if (memberCount > 1) {
        _showAlert('ไม่สามารถออกจากกลุ่มได้',
            'คุณต้องให้สมาชิกทั้งหมดออกก่อนถึงจะออกจากกลุ่มได้');
        return;
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('ออกจากกลุ่ม'),
          content: Text('ต้องการออกจากกลุ่มใช่ไหม'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () async {
                final groupRef = FirebaseFirestore.instance
                    .collection('groups')
                    .doc(widget.groupId);
                await groupRef
                    .collection('userlist')
                    .doc(widget.currentUserId)
                    .delete();
                await groupRef.delete();

                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ออกจากกลุ่มแล้ว')));
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => ShowChatScreen()));
              },
              child: Text('ตกลง'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('ออกจากกลุ่ม'),
        content: Text('ต้องการออกจากกลุ่มใช่ไหม'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () async {
              final groupRef = FirebaseFirestore.instance
                  .collection('groups')
                  .doc(widget.groupId);
              await Future.wait([
                groupRef
                    .collection('pending')
                    .doc(widget.currentUserId)
                    .delete(),
                groupRef
                    .collection('userlist')
                    .doc(widget.currentUserId)
                    .delete(),
              ]);

              final userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.currentUserId)
                  .get();

              currentusername = userDoc.data()?['username'];

              await _firestore
                  .collection('groups')
                  .doc(widget.groupId)
                  .collection('messages')
                  .add({
                'type': 'notification',
                'text': '$currentusername ได้ออกจากกลุ่มแล้ว',
                'senderId': 'server',
                'setTime': FieldValue.serverTimestamp(),
              });
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ออกจากกลุ่มแล้ว')));
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => ShowChatScreen()));
            },
            child: Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPurchase() async {
    if (hasConfirmedPurchase) return;

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('confirmations')
        .doc(widget.currentUserId)
        .set({'confirmedAt': FieldValue.serverTimestamp()});

    setState(() => hasConfirmedPurchase = true);
  }

  Future<void> _cancelConfirmation() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('ยืนยันการยกเลิก'),
        content: Text('คุณต้องการยกเลิกการยืนยันการซื้อหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ไม่'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('groups')
                  .doc(widget.groupId)
                  .collection('confirmations')
                  .doc(widget.currentUserId)
                  .delete();

              setState(() => hasConfirmedPurchase = false);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ยกเลิกการยืนยันการซื้อแล้ว')));
            },
            child: Text('ใช่'),
          ),
        ],
      ),
    );
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return DateFormat('HH:mm').format(timestamp.toDate());
    }
    return timestamp is String ? timestamp : 'Invalid timestamp';
  }

  Future<String> _getUserName(String userId) async {
    DocumentSnapshot doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    return doc.exists ? doc['username'] : "";
  }

  Future<void> _changeGroupStatus() async {
    if (!isGroupLeader) {
      _showSnackBar('เฉพาะหัวหน้ากลุ่มเท่านั้นที่สามารถเปลี่ยนสถานะได้');
      return;
    }

    var groupRef = _firestore.collection('groups').doc(widget.groupId);
    var members = await groupRef.collection('userlist').get();

    if (groupStatus == '1' && members.size < groupSize!) {
      _showSnackBar('ต้องรอให้สมาชิกทุกคนเข้าร่วมกลุ่มก่อน');
      return;
    }

    if (groupStatus == '2') {
      var confirmations = await groupRef.collection('confirmations').get();
      if (confirmations.size < members.size) {
        _showSnackBar('ต้องรอให้สมาชิกทุกคนยืนยันการซื้อก่อน');
        return;
      }
    }

    if (groupStatus != null) {
      int newStatus = (int.parse(groupStatus!) % 4) + 1;
      await groupRef.update({'groupStatus': newStatus});
      setState(() => groupStatus = newStatus.toString());
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 1:
        return 'กำลังยืนยันการแชร์';
      case 2:
        return 'กำลังดำเนินการซื้อ';
      case 3:
        return 'กำลังดำเนินการนัดรับ';
      case 4:
        return 'นัดรับสำเร็จแล้ว';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }

  void _showStatusChangeConfirmation() {
    if (!isGroupLeader) {
      _showSnackBar('เฉพาะหัวหน้ากลุ่มเท่านั้นที่สามารถเปลี่ยนสถานะได้');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.yellow[100],
        contentPadding: EdgeInsets.all(16.0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusText(int.parse(groupStatus!), isGrey: true),
            Icon(Icons.arrow_drop_down, size: 48),
            _buildStatusText(int.parse(groupStatus!) + 1),
            if (groupStatus != "3") ...[
              Icon(Icons.arrow_drop_down, size: 48),
              _buildStatusText(int.parse(groupStatus!) + 2, isGrey: true),
            ],
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          _buildActionButton('ยืนยันการซื้อ', true, () {
            Navigator.pop(context);
            _changeGroupStatus();
          }),
          _buildActionButton('ยกเลิก', false, () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _buildStatusText(int status, {bool isGrey = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: isGrey ? 16 : 24,
          color: isGrey ? Colors.grey : Colors.black,
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String text, bool isConfirm, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isConfirm
            ? Color.fromARGB(255, 71, 255, 78)
            : Color.fromARGB(255, 239, 108, 98),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showLocationDialog(BuildContext context) {
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ตำแหน่งไม่พร้อมใช้งาน')),
      );
      return;
    }

    final location = LatLng(latitude!, longitude!);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('ตำแหน่งที่ปักหมุด'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: location, zoom: 14.0),
            markers: {
              Marker(
                markerId: MarkerId('selected-location'),
                position: location,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed),
              ),
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('ตกลง'),
          ),
        ],
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

  Widget _buildUserListTile(
      BuildContext context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
    if (userSnapshot.connectionState == ConnectionState.waiting) {
      return ListTile(
        leading: CircleAvatar(child: CircularProgressIndicator()),
        title: Text('กำลังโหลด...'),
      );
    }

    if (!userSnapshot.hasData || !userSnapshot.data!.exists)
      return SizedBox.shrink();

    final userData = userSnapshot.data!.data() as Map<String, dynamic>;
    final userId = userSnapshot.data!.id;
    final hasImage =
        userData['imageUrl'] != null && userData['imageUrl'].isNotEmpty;

    return ListTile(
      leading: GestureDetector(
        onTap: () => _navigateToProfileScreen(userData['userId']),
        child: CircleAvatar(
          backgroundImage: hasImage ? NetworkImage(userData['imageUrl']) : null,
          child: hasImage ? null : Icon(Icons.person),
        ),
      ),
      title: GestureDetector(
        onTap: () => _navigateToProfileScreen(userData['userId']),
        child: Text(
          userData['username'] ?? 'ไม่มีชื่อผู้ใช้',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      subtitle: Text(
        '${userData['fname'] ?? ''} ${userData['lname'] ?? ''}',
        style: GoogleFonts.anuphan(),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (userId == groupLeaderId)
            FaIcon(FontAwesomeIcons.crown, size: 16, color: Colors.yellow),
          SizedBox(width: 8),
          if (isGroupLeader &&
              groupStatus != '3' &&
              userId != widget.currentUserId)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _kickMember(userId),
              color: Colors.red,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
            child: Text('แชท',
                style: GoogleFonts.anuphan(fontWeight: FontWeight.bold))),
        backgroundColor: AppTheme.appBarColor,
        actions: [
          IconButton(icon: Icon(Icons.person), onPressed: _showuserlist),
          IconButton(icon: Icon(Icons.exit_to_app), onPressed: _leaveGroup),
        ],
      ),
      body: Container(
        color: AppTheme.backgroundColor,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8),
              color: Color.fromARGB(212, 219, 219, 219),
              child: Center(
                child: Text(groupName ?? 'กำลังโหลดชื่อกลุ่ม...',
                    style: GoogleFonts.anuphan(
                        fontSize: 30, fontWeight: FontWeight.bold)),
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4),
              color: Color.fromARGB(255, 195, 195, 195),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      RichText(
                        text: TextSpan(
                          text: 'สถานะ : ',
                          style: GoogleFonts.anuphan(
                              fontSize: 18, color: Colors.black),
                          children: [
                            TextSpan(
                              text: groupStatus != null
                                  ? _getStatusText(int.parse(groupStatus!))
                                  : 'กำลังโหลดสถานะ...',
                              style: GoogleFonts.anuphan(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      if (isGroupLeader && groupStatus != "4")
                        IconButton(
                            icon: Icon(Icons.play_circle_fill),
                            color: Color.fromARGB(255, 46, 95, 179),
                            onPressed: _showStatusChangeConfirmation),
                    ],
                  ),
                  TextButton(
                      onPressed: () => _showLocationDialog(context),
                      child: Text('ดูสถานที่นัดรับ',
                          style: GoogleFonts.anuphan(
                              color: Colors.red, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8),
              color: Color.fromARGB(212, 219, 219, 219),
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('groups')
                    .doc(widget.groupId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return CircularProgressIndicator();
                  if (snapshot.hasData)
                    return Text(
                        'เวลานัดรับสินค้า: ${GroupChat.formatThaiDateTime(snapshot.data!['setTime'])}',
                        style:
                            GoogleFonts.anuphan(fontWeight: FontWeight.bold));
                  return Text('ไม่สามารถโหลดข้อมูลได้');
                },
              ),
            ),
            if (groupStatus == '2')
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('groups')
                        .doc(widget.groupId)
                        .collection('confirmations')
                        .snapshots(),
                    builder: (context, snapshot) {
                      int confirmedCount =
                          snapshot.hasData ? snapshot.data!.size : 0;
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            child: Text(
                                'ยืนยันการซื้อแล้ว: $confirmedCount/${groupSize ?? 0} คน',
                                style: GoogleFonts.anuphan(
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      );
                    },
                  ),
                  if (!hasConfirmedPurchase)
                    ElevatedButton(
                      onPressed: _confirmPurchase,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          minimumSize: Size(100, 25),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child:
                          Text('ยืนยันการซื้อ', style: GoogleFonts.anuphan()),
                    ),
                  if (hasConfirmedPurchase)
                    ElevatedButton(
                      onPressed: _cancelConfirmation,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: Size(100, 25),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: Text('ยกเลิกการยืนยัน',
                          style: GoogleFonts.anuphan(color: Colors.white)),
                    ),
                ],
              ),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('groups')
                    .doc(widget.groupId)
                    .collection('messages')
                    .orderBy('setTime', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                    return Center(
                        child: Text('ไม่มีข้อความในกลุ่มนี้',
                            style: GoogleFonts.anuphan()));
                  return ListView.builder(
                    reverse: true,
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var messageData = snapshot.data!.docs[index];
                      String senderId = messageData['senderId'];
                      var setTime = messageData['setTime'];
                      bool isCurrentUser = senderId == widget.currentUserId;
                      bool isServer = senderId == "server";

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        child: Align(
                          alignment: isServer
                              ? Alignment.center
                              : (isCurrentUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft),
                          child: Column(
                            crossAxisAlignment: isServer
                                ? CrossAxisAlignment.center
                                : (isCurrentUser
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start),
                            children: [
                              FutureBuilder<String>(
                                future: _getUserName(senderId),
                                builder: (context, snapshot) {
                                  String userName =
                                      snapshot.data ?? 'กำลังโหลดชื่อ...';
                                  return Row(
                                    mainAxisAlignment: isServer
                                        ? MainAxisAlignment.center
                                        : (isCurrentUser
                                            ? MainAxisAlignment.end
                                            : MainAxisAlignment.start),
                                    children: [
                                      if (senderId == groupLeaderId)
                                        Padding(
                                            padding:
                                                EdgeInsets.only(right: 6.0),
                                            child: FaIcon(
                                                FontAwesomeIcons.crown,
                                                size: 16,
                                                color: Colors.yellow)),
                                      Text(userName,
                                          style: GoogleFonts.anuphan(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black)),
                                    ],
                                  );
                                },
                              ),
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    color: isServer
                                        ? Colors.grey[
                                            200] // สีพื้นหลังสำหรับข้อความ server
                                        : (isCurrentUser
                                            ? Colors.blue[100]
                                            : Colors.grey[300]),
                                    borderRadius: BorderRadius.circular(10)),
                                child: messageData['type'] == 'image'
                                    ? Image.network(messageData['imageUrl'],
                                        width: 200,
                                        height: 200,
                                        fit: BoxFit.cover, loadingBuilder:
                                            (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Center(
                                            child: CircularProgressIndicator(
                                                value: loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                    : null));
                                      })
                                    : Text(messageData['text'] ?? '',
                                        style:
                                            GoogleFonts.anuphan(fontSize: 16)),
                              ),
                              Text(
                                  setTime != null
                                      ? _formatTimestamp(setTime)
                                      : 'กำลังประมวลผล...',
                                  style: GoogleFonts.anuphan(
                                      fontSize: 12, color: Colors.grey)),
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
                  if (_selectedImage == null)
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                            hintText: 'พิมพ์ข้อความ...',
                            border: OutlineInputBorder()),
                      ),
                    )
                  else
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.image),
                        label: Text('ยกเลิก', style: GoogleFonts.anuphan()),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12)),
                        onPressed: _cancelSelectedImage,
                      ),
                    ),
                  if (_selectedImage == null)
                    IconButton(
                        icon: Icon(Icons.photo), onPressed: _selectImage),
                  IconButton(
                      icon: Icon(Icons.send),
                      onPressed: () => _selectedImage != null
                          ? _sendImageMessage()
                          : _sendMessage()),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerTop,
      floatingActionButton: groupStatus == '4'
          ? StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .doc(widget.groupId)
                  .collection('userlist')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting ||
                    !snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) return SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 375),
                  child: FloatingActionButton(
                    child: Icon(Icons.rate_review),
                    onPressed: () => snapshot.data!.docs.forEach((doc) {
                      if (doc.id != widget.currentUserId)
                        _showReviewDialog(doc.id);
                    }),
                  ),
                );
              },
            )
          : null,
    );
  }
}
