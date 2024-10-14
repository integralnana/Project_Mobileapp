import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  Future<void> _sendVerificationEmail() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && !currentUser.emailVerified) {
        await currentUser.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Verification email sent! Please check your inbox.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email is already verified.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending verification email: $e')),
      );
    }
  }

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
      backgroundColor: Colors.pink[100],
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _image != null
                    ? FileImage(_image!) as ImageProvider<Object>
                    : (_imageUrl != null
                        ? NetworkImage(_imageUrl!) as ImageProvider<Object>
                        : null),
                backgroundColor: Colors.grey[300],
                child: _image == null && _imageUrl == null
                    ? Icon(Icons.camera_alt, size: 50)
                    : null,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _fnameController,
              decoration: InputDecoration(labelText: 'First Name'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _lnameController,
              decoration: InputDecoration(labelText: 'Last Name'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _updateUserProfile,
              child: Text('Save Changes'),
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.pink[100]),
            ),
          ],
        ),
      ),
    );
  }
}
