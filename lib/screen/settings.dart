import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projectapp/constant.dart';

class SettingScreen extends StatefulWidget {
  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final _fnameController = TextEditingController();
  final _lnameController = TextEditingController();
  File? _image;
  String? _imageUrl;
  String? _userId; // Store the logged-in user's ID

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Send verification email

  Future<void> _loadUserData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      _userId = currentUser.uid;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          _fnameController.text = userDoc['fname'];
          _lnameController.text = userDoc['lname'];
          _imageUrl = userDoc['imageUrl'];
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
      });
    }
  }

  Future<void> _updateUserProfile() async {
    try {
      String? downloadUrl;

      // ถ้ามีรูปที่เลือก ก็อัปโหลดไปที่ Firebase Storage
      if (_image != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('$_userId.jpg'); // เก็บรูปใน user_images/ ตาม userId

        await ref.putFile(_image!); // อัปโหลดไฟล์รูปภาพ
        downloadUrl = await ref.getDownloadURL(); // ดึง URL ของรูปที่อัปโหลด

        setState(() {
          _imageUrl = downloadUrl; // เก็บ URL รูปที่อัปโหลดในตัวแปร _imageUrl
        });
      }

      // อัปเดตข้อมูลผู้ใช้ใน Firestore รวมถึง imageUrl ถ้ามีการเปลี่ยนแปลง
      await FirebaseFirestore.instance.collection('users').doc(_userId).update({
        'fname': _fnameController.text,
        'lname': _lnameController.text,
        'imageUrl': _imageUrl, // อัปเดต URL ของรูปภาพ
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('โปรไฟล์ได้รับการอัปเดตเรียบร้อย')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปเดตโปรไฟล์: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarColor,
        title: const Text('ตั้งค่าโปรไฟล์'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            _buildProfileImage(),
            const SizedBox(height: 32),
            _buildProfileForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryColor,
                width: 3,
              ),
            ),
            child: ClipOval(
              child: _image != null
                  ? Image.file(_image!, fit: BoxFit.cover)
                  : _imageUrl != null
                      ? Image.network(_imageUrl!, fit: BoxFit.cover)
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey,
                          ),
                        ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ข้อมูลส่วนตัว',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _fnameController,
            decoration: const InputDecoration(
              labelText: 'ชื่อ',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lnameController,
            decoration: const InputDecoration(
              labelText: 'นามสกุล',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _updateUserProfile,
            child: const Text('บันทึกการเปลี่ยนแปลง'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
