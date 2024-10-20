import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:projectapp/model/groupchat.dart';
import 'package:projectapp/screen/locationpicker.dart';

class createpostScreen extends StatefulWidget {
  @override
  _createpostScreenState createState() => _createpostScreenState();
}

class _createpostScreenState extends State<createpostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _groupDescController = TextEditingController();
  String? _groupImageUrl;
  int _groupSize = 2;
  int _groupType = 1;
  String _productCategory = 'อาหาร'; // New variable for product category
  DateTime? _selectedDateTime;
  LatLng? _selectedLocation;

  final ImagePicker _picker = ImagePicker();

  // List of product categories
  final List<String> _categories = ['อาหาร', 'ของใช้', 'อาหารสัตว์', 'อื่นๆ'];

  Future<void> _uploadImage() async {
    final XFile? pickedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage == null) return;

    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageReference =
        FirebaseStorage.instance.ref().child('groupImages/$fileName');
    await storageReference.putFile(File(pickedImage.path));
    String downloadUrl = await storageReference.getDownloadURL();
    setState(() {
      _groupImageUrl = downloadUrl;
    });
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
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

  Future<void> _navigateAndPickLocation() async {
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

  Future<void> _createGroup() async {
    if (_formKey.currentState!.validate() &&
        _groupImageUrl != null &&
        _selectedLocation != null &&
        _selectedDateTime != null) {
      try {
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please login to create a group')),
          );
          return;
        }

        DocumentReference docRef =
            FirebaseFirestore.instance.collection('groups').doc();
        String groupId = docRef.id;

        // Fetch the current user's username
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        String username = userDoc['username'] ?? 'Unknown User';

        await docRef.set({
          'groupId': groupId,
          'groupName': _groupNameController.text,
          'groupImage': _groupImageUrl,
          'groupSize': _groupSize,
          'groupType': _groupType,
          'productCategory': _productCategory, // New field
          'groupDesc': _groupDescController.text,
          'createdAt': _selectedDateTime,
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
          'userId': currentUser.uid,
          'username': username,
          'groupStatus': '1',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Group created successfully')),
        );
        Navigator.pop(context); // Return to SharingScreen
      } catch (e) {
        print('Error creating group: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating group. Please try again.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('หน้าสร้างโพสต์'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _uploadImage,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _groupImageUrl == null
                          ? Icon(Icons.add_a_photo,
                              size: 50, color: Colors.grey[400])
                          : Image.network(_groupImageUrl!, fit: BoxFit.cover),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _groupNameController,
                  decoration: InputDecoration(
                    labelText: 'หัวข้อ/ชื่อสินค้า',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a group name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _productCategory,
                  decoration: InputDecoration(
                    labelText: 'ประเภทสินค้า',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _productCategory = newValue!;
                    });
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _groupSize,
                  decoration: InputDecoration(
                    labelText: 'จำนวนคนที่รับ',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(9, (index) => index + 2)
                      .map((size) => DropdownMenuItem<int>(
                            value: size,
                            child: Text('$size คน'),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _groupSize = value!),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _groupType,
                  decoration: InputDecoration(
                    labelText: 'ประเภทการจ่ายเงิน',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem<int>(value: 1, child: Text('จ่ายก่อนรับ')),
                    DropdownMenuItem<int>(value: 2, child: Text('จ่ายตอนรับ')),
                  ],
                  onChanged: (value) => setState(() => _groupType = value!),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _groupDescController,
                  decoration: InputDecoration(
                    labelText: 'รายละเอียด',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _selectDateTime(context),
                        icon: Icon(Icons.calendar_today),
                        label: Text(_selectedDateTime == null
                            ? 'เลือกวันและเวลานัดรับ'
                            : '${_selectedDateTime!.day}/${_selectedDateTime!.month}/${_selectedDateTime!.year} ${_selectedDateTime!.hour}:${_selectedDateTime!.minute}'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _navigateAndPickLocation,
                  icon: Icon(Icons.location_on),
                  label: Text(_selectedLocation == null
                      ? 'เลือกสถานที่นัดรับ'
                      : 'สถานที่นัดรับที่เลือกแล้ว'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: _createGroup,
                    child: Text('สร้างโพสต์'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      padding:
                          EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
