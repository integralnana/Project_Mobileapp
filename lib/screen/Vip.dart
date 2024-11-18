import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projectapp/constant.dart';
import 'package:intl/intl.dart';

class VipSubScreen extends StatefulWidget {
  @override
  _VipSubScreenState createState() => _VipSubScreenState();
}

class _VipSubScreenState extends State<VipSubScreen> {
  File? _image;
  final picker = ImagePicker();
  bool _isLoading = false;
  bool _isVip = false;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _checkVipStatus();
  }

  Future<void> _checkVipStatus() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // ตรวจสอบสถานะ VIP จาก collection users
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        if (userData['status'] == "2") {
          // ดึงข้อมูลวันที่จาก subcollection vipstatus
          DocumentSnapshot vipStatusDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .collection('vipstatus')
              .doc(currentUser.uid)
              .get();

          if (vipStatusDoc.exists) {
            Map<String, dynamic> vipData =
                vipStatusDoc.data() as Map<String, dynamic>;
            setState(() {
              _isVip = true;
              _startDate = (vipData['startedAt'] as Timestamp).toDate();
              _endDate = (vipData['expiredAt'] as Timestamp).toDate();
            });
          }
        }
      }
    } catch (e) {
      print('Error checking VIP status: $e');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<String?> _uploadImageToStorage(File imageFile) async {
    try {
      String fileName = 'slip_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final Reference storageRef =
          FirebaseStorage.instance.ref().child('vip_slips').child(fileName);

      await storageRef.putFile(imageFile);

      String downloadURL = await storageRef.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _uploadAndSendEmail() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณาเลือกรูปสลิปการโอนเงิน')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('ไม่พบข้อมูลผู้ใช้');
      }
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      Map<String, dynamic>? userData =
          userSnapshot.data() as Map<String, dynamic>?;
      String username = userData?['username'] ?? 'Unknown';

      String? imageUrl = await _uploadImageToStorage(_image!);
      if (imageUrl == null) {
        throw Exception('ไม่สามารถอัพโหลดรูปภาพได้');
      }

      await FirebaseFirestore.instance.collection('vip').add({
        'userId': currentUser.uid,
        'username': username,
        'slipImage': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ส่งคำขอสมัครสมาชิก VIP เรียบร้อยแล้ว')),
      );

      await Future.delayed(Duration(seconds: 1));
      Navigator.of(context).pop();
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: กรุณาลองใหม่อีกครั้ง')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildVipStatusInfo() {
    if (!_isVip) return SizedBox.shrink();

    final dateFormat = DateFormat('dd/MM/yyyy');
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green),
      ),
      child: Column(
        children: [
          Text(
            'คุณเป็นสมาชิก VIP แล้ว',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          SizedBox(height: 8),
          Text('วันที่เริ่มต้น: ${dateFormat.format(_startDate!)}'),
          Text('วันที่หมดอายุ: ${dateFormat.format(_endDate!)}'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_isLoading,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text('สมัครVIP'),
          backgroundColor: AppTheme.appBarColor,
          centerTitle: true,
          leading: _isLoading
              ? Container()
              : IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildVipStatusInfo(),
                if (!_isVip) ...[
                  SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Image.asset(
                        'assets/images/QRPayment.png',
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'แพคเกจ 1 เดือน : 100 บาท',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'โปรดส่งสลิปหลังชำระเงิน',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  SizedBox(height: 16),
                  GestureDetector(
                    onTap: _isLoading ? null : _pickImage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black),
                      ),
                      child: _image == null
                          ? Container(
                              width: double.infinity,
                              height: 200,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.add,
                                size: 50,
                                color: Colors.black,
                              ),
                            )
                          : Image.file(
                              _image!,
                              width: double.infinity,
                              fit: BoxFit.contain,
                            ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: _isLoading
                        ? CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _uploadAndSendEmail,
                            child: Text('ยืนยันการสมัครสมาชิก'),
                          ),
                  ),
                  SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
