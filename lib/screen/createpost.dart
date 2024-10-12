import 'dart:io';
import 'package:projectapp/screen/locationpicker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projectapp/model/groupchat.dart';

class createpostScreen extends StatefulWidget {
  @override
  _createpostScreenState createState() => _createpostScreenState();
}

class _createpostScreenState extends State<createpostScreen> {
  LatLng? _selectedLocation;
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _groupDesc = TextEditingController();
  String? _groupImageUrl;
  int _groupSize = 2;
  int _groupType = 1;
  final ImagePicker _picker = ImagePicker();
  DateTime? _selectedDateTime; // ตัวแปรสำหรับเก็บวันและเวลา

  void _selectLocation(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  Future<void> _navigateAndPickLocation() async {
    // ไปยังหน้าเลือกแผนที่ และรับพิกัดเมื่อกดตกลง
    final LatLng? pickedLocation = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LocationPickerScreen()),
    );

    if (pickedLocation != null) {
      setState(() {
        _selectedLocation = pickedLocation;
      });
    }
  }

  // ฟังก์ชันสำหรับการเลือกวันและเวลา
  Future<void> _selectDateTime(BuildContext context) async {
    // เลือกวันที่
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      // เลือกเวลา
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        // รวมวันที่และเวลาเข้าด้วยกัน
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

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
    if (_formKey.currentState!.validate() &&
        _groupImageUrl != null &&
        _selectedLocation != null) {
      DocumentReference docRef =
          FirebaseFirestore.instance.collection('groups').doc();
      String groupId = docRef.id;

      // สร้างกลุ่มใหม่พร้อม groupId และ createdAt
      GroupChat newGroup = GroupChat(
        groupId: groupId,
        groupName: _groupNameController.text,
        groupImage: _groupImageUrl!,
        groupSize: _groupSize,
        groupType: _groupType,
        groupDesc: _groupDesc.text,
        createdAt: _selectedDateTime!,
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
      );

      // บันทึกกลุ่มใหม่ใน Firestore
      await docRef.set(newGroup.toJson());

      // แสดงข้อความเมื่อสร้างเสร็จแล้ว
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Group created successfully')));
      Navigator.pop(context); // กลับไปยังหน้าหลัก
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Please upload a group image and select date/time')));
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
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        TextFormField(
                          controller: _groupDesc,
                          decoration:
                              InputDecoration(labelText: 'Group Description'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a group description';
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

              // อินพุตสำหรับเลือกวันและเวลา
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: _selectedDateTime == null
                            ? 'Select Date & Time'
                            : _selectedDateTime!.toString(),
                      ),
                      onTap: () => _selectDateTime(context),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDateTime(context),
                  ),
                ],
              ),
              SizedBox(height: 24.0),

              // แผนที่ Google Map
              ElevatedButton(
                onPressed: _navigateAndPickLocation,
                child: Text('เลือกสถานที่'),
              ),
              if (_selectedLocation != null)
                Text(
                  'ตำแหน่งที่เลือก: (${_selectedLocation!.latitude}, ${_selectedLocation!.longitude})',
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
