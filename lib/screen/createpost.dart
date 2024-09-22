import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projectapp/model/groupchat.dart';

class createpostScreen extends StatefulWidget {
  @override
  _createpostScreenState createState() => _createpostScreenState();
}

class _createpostScreenState extends State<createpostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  String? _groupImageUrl;
  int _groupSize = 2;
  int _groupType = 1;
  final ImagePicker _picker = ImagePicker();

  // Upload image to Firebase Storage and get URL
  Future<void> _uploadImage() async {
    final XFile? pickedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageReference =
          FirebaseStorage.instance.ref().child('groupImages/$fileName');
      await storageReference.putFile(File(pickedImage.path));
      String downloadUrl = await storageReference.getDownloadURL();
      setState(() {
        _groupImageUrl = downloadUrl;
      });
    }
  }

  Future<void> _createGroup() async {
    if (_formKey.currentState!.validate() && _groupImageUrl != null) {
      // สร้างเอกสารใหม่ใน Firestore และรับ docId
      DocumentReference docRef =
          FirebaseFirestore.instance.collection('groups').doc();
      String groupId = docRef.id;

      // สร้างกลุ่มใหม่พร้อม groupId
      GroupChat newGroup = GroupChat(
        groupId: groupId,
        groupName: _groupNameController.text,
        groupImage: _groupImageUrl!,
        groupSize: _groupSize,
        groupType: _groupType,
      );

      // บันทึกกลุ่มใหม่ใน Firestore
      await docRef.set(newGroup.toJson());

      // แสดงข้อความเมื่อสร้างเสร็จแล้ว
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Group created successfully')));
      Navigator.pop(context); // กลับไปยังหน้าหลัก
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please upload a group image')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Group')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start, // จัดการแนวตั้ง
                children: [
                  // ส่วนรูปภาพอยู่ด้านซ้าย
                  GestureDetector(
                    onTap: _uploadImage,
                    child: _groupImageUrl == null
                        ? Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              border: Border.all(),
                            ),
                            child: Icon(Icons.add_a_photo, size: 50),
                          )
                        : Image.network(
                            _groupImageUrl!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                  ),
                  SizedBox(width: 16.0), // ระยะห่างระหว่างรูปและคอลัมน์

                  // ส่วนของชื่อกลุ่ม จำนวนสมาชิก และประเภท
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ชื่อกลุ่ม
                        TextFormField(
                          controller: _groupNameController,
                          decoration: InputDecoration(labelText: 'Group Name'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a group name';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16.0),

                        // จำนวนสมาชิก
                        DropdownButtonFormField<int>(
                          value: _groupSize,
                          decoration: InputDecoration(labelText: 'Group Size'),
                          items: List.generate(9, (index) => index + 2)
                              .map((size) {
                            return DropdownMenuItem<int>(
                              value: size,
                              child: Text('$size members'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _groupSize = value!;
                            });
                          },
                        ),
                        SizedBox(height: 16.0),

                        // ประเภทกลุ่ม
                        DropdownButtonFormField<int>(
                          value: _groupType,
                          decoration: InputDecoration(labelText: 'Group Type'),
                          items: [
                            DropdownMenuItem<int>(
                                value: 1, child: Text('Type 1')),
                            DropdownMenuItem<int>(
                                value: 2, child: Text('Type 2')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _groupType = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.0),

              // ปุ่มสร้างกลุ่ม
              ElevatedButton(
                onPressed: _createGroup,
                child: Text('Create Group'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
