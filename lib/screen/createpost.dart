import 'dart:io';
import 'package:projectapp/constant.dart';
import 'package:projectapp/model/groupchat.dart';
import 'package:projectapp/screen/locationpicker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  DateTime? _selectedDateTime;

  void _selectLocation(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
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

  Future<void> _selectDateTime(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
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

  Future<void> _uploadImage() async {
    final XFile? pickedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please select an image'),
      ));
      return;
    }

    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageReference =
        FirebaseStorage.instance.ref().child('groupImages/$fileName');
    await storageReference.putFile(File(pickedImage.path));
    String downloadUrl = await storageReference.getDownloadURL();
    setState(() {
      _groupImageUrl = downloadUrl;
    });
  }

  Future<String> _getUsernameFromFirestore(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists && userDoc['username'] != null) {
        return userDoc['username'];
      } else {
        return 'Unknown';
      }
    } catch (e) {
      print('Error fetching username: $e');
      return 'Unknown';
    }
  }

  Future<void> _createGroup() async {
    if (_formKey.currentState!.validate() &&
        _groupImageUrl != null &&
        _selectedLocation != null &&
        _selectedDateTime != null) {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please login to create a group')));
        return;
      }

      String userId = currentUser.uid;
      String username = await _getUsernameFromFirestore(userId);

      DocumentReference docRef =
          FirebaseFirestore.instance.collection('groups').doc();
      String groupId = docRef.id;

      GroupChat newGroup = GroupChat(
          groupId: groupId,
          groupName: _groupNameController.text,
          groupImage: _groupImageUrl!,
          groupSize: _groupSize,
          groupType: _groupType,
          groupDesc: _groupDesc.text,
          setTime: _selectedDateTime!,
          latitude: _selectedLocation!.latitude,
          longitude: _selectedLocation!.longitude,
          userId: userId,
          username: username,
          groupStatus: '1');

      await docRef.set(newGroup.toJson());

      await docRef.collection('userlist').doc(userId).set({
        'userId': userId,
        'username': username,
      });
      await docRef.collection('pending').doc(userId).set({});

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Group created successfully')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Please complete all fields and select date/time')));
    }
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageSection(),
          const SizedBox(height: 24),
          _buildDetailsSection(),
          const SizedBox(height: 24),
          _buildDateTimeSection(),
          const SizedBox(height: 24),
          _buildLocationSection(),
          const SizedBox(height: 32),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return GestureDetector(
      onTap: _uploadImage,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: _groupImageUrl == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('เพิ่มรูปภาพ', style: TextStyle(color: Colors.grey)),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  _groupImageUrl!,
                  fit: BoxFit.cover,
                ),
              ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _groupNameController,
          decoration: const InputDecoration(
            labelText: 'หัวข้อ',
            prefixIcon: Icon(Icons.title),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _groupDesc,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'รายละเอียด',
            prefixIcon: Icon(Icons.description),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                value: _groupSize,
                label: 'จำนวน',
                icon: Icons.group,
                items: List.generate(9, (index) => index + 2)
                    .map((size) => DropdownMenuItem(
                          value: size,
                          child: Text('$size คน'),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _groupSize = value!),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                value: _groupType,
                label: 'การชำระเงิน',
                icon: Icons.payment,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('โอนก่อน')),
                  DropdownMenuItem(value: 2, child: Text('จ่ายหลังนัดรับ')),
                ],
                onChanged: (value) => setState(() => _groupType = value!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required dynamic value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem> items,
    required Function(dynamic) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonFormField(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: InputBorder.none,
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'วันและเวลานัดรับ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  readOnly: true,
                  decoration: const InputDecoration(
                    hintText: 'เลือกวันและเวลา',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () => _selectDateTime(context),
                  controller: TextEditingController(
                    text: _selectedDateTime?.toString() ?? '',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สถานที่นัดรับ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _navigateAndPickLocation,
            icon: const Icon(Icons.location_on),
            label: const Text('เลือกสถานที่'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _createGroup,
      child: const Text('สร้างโพสต์'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarColor,
        title: const Text('สร้างโพสต์ใหม่'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: _buildForm(),
          ),
        ),
      ),
    );
  }
}