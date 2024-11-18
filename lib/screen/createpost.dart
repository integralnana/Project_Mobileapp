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

class CreatePostScreen extends StatefulWidget {
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _groupDesc = TextEditingController();
  final _picker = ImagePicker();

  LatLng? _selectedLocation;
  String? _groupImageUrl;
  int _groupSize = 2;
  int _groupType = 1;
  DateTime? _selectedDateTime;
  String _selectedCategory = GroupChat.categories[0];
  String _userStatus = "1"; // Default status
  int _maxGroupSize = 4; // Default max group size

  @override
  void initState() {
    super.initState();
    _loadUserStatus();
  }

  Future<void> _loadUserStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      setState(() {
        _userStatus = userDoc.data()?['status'] ?? "1";
        _maxGroupSize = _userStatus == "2" ? 10 : 4;
      });
    }
  }

  Future<void> _pickLocation() async {
    final location = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (_) => LocationPickerScreen()),
    );
    if (location != null) setState(() => _selectedLocation = location);
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _uploadImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final ref = FirebaseStorage.instance
        .ref()
        .child('groupImages/${DateTime.now().millisecondsSinceEpoch}');
    await ref.putFile(File(image.path));
    _groupImageUrl = await ref.getDownloadURL();
    setState(() {});
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate() ||
        _groupImageUrl == null ||
        _selectedLocation == null ||
        _selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('กรุณาเข้าสู่ระบบ')));
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final username = userDoc.data()?['username'] ?? 'Unknown';

    final groupRef = FirebaseFirestore.instance.collection('groups').doc();
    final group = GroupChat(
      groupId: groupRef.id,
      groupName: _groupNameController.text,
      groupImage: _groupImageUrl!,
      groupSize: _groupSize,
      groupType: _groupType,
      groupDesc: _groupDesc.text,
      setTime: Timestamp.fromDate(_selectedDateTime!),
      latitude: _selectedLocation!.latitude,
      longitude: _selectedLocation!.longitude,
      userId: user.uid,
      username: username,
      groupStatus: '1',
      groupCate: _selectedCategory,
      groupGenre: 1,
    );

    await groupRef.set(group.toJson());
    await groupRef.collection('userlist').doc(user.uid).set({
      'userId': user.uid,
      'username': username,
    });
    await groupRef.collection('pending').doc(user.uid).set({});
    await groupRef.collection('pending').doc(user.uid).delete();

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('สร้างโพสต์สำเร็จ')));
    Navigator.pop(context);
  }

  Widget _buildImagePicker() => GestureDetector(
        onTap: _uploadImage,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: _groupImageUrl == null
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('เพิ่มรูปภาพ', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(_groupImageUrl!, fit: BoxFit.cover),
                ),
        ),
      );

  Widget _buildForm() => Padding(
        padding: const EdgeInsets.all(1.0),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePicker(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  labelText: 'หัวข้อ',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'กรุณากรอกหัวข้อ' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'หมวดหมู่',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: GroupChat.categories
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _groupDesc,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'รายละเอียด',
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (v) =>
                    v?.isEmpty ?? true ? 'กรุณากรอกรายละเอียด' : null,
              ),
              const SizedBox(height: 16),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Flexible(
                      flex: 1,
                      child: DropdownButtonFormField(
                        value: _groupSize,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'จำนวน',
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          prefixIcon: Icon(Icons.group),
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(_maxGroupSize - 1, (i) => i + 2)
                            .map((size) => DropdownMenuItem(
                                  value: size,
                                  child: Text('$size คน'),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _groupSize = v as int),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      flex: 1,
                      child: DropdownButtonFormField(
                        value: _groupType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'การชำระเงิน',
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          prefixIcon: Icon(Icons.payment),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('โอนก่อน')),
                          DropdownMenuItem(
                              value: 2, child: Text('จ่ายหลังนัดรับ')),
                        ],
                        onChanged: (v) => setState(() => _groupType = v as int),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                controller: TextEditingController(
                  text: _selectedDateTime?.toString() ?? '',
                ),
                decoration: const InputDecoration(
                  labelText: 'วันและเวลานัดรับ',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                onTap: _pickDateTime,
                validator: (v) =>
                    _selectedDateTime == null ? 'กรุณาเลือกเวลา' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickLocation,
                icon: const Icon(Icons.location_on),
                label: Text(_selectedLocation == null
                    ? 'เลือกสถานที่'
                    : 'เปลี่ยนสถานที่'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _createGroup,
                child: const Text('สร้างโพสต์'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.appBarColor,
          title: const Text('สร้างโพสต์ใหม่'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: _buildForm(),
          ),
        ),
      );
}
