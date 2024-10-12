import 'dart:io';
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
        createdAt: _selectedDateTime!,
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        userId: userId,
        username: username,
      );

      await docRef.set(newGroup.toJson());

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Group created successfully')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Please complete all fields and select date/time')));
    }
  }

  Widget _buildForm() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _uploadImage,
              child: _buildGroupImagePicker(),
            ),
            SizedBox(width: 16.0),
            Expanded(child: _buildGroupDetailsForm())
          ],
        ),
        SizedBox(height: 24.0),
        _buildDateTimePicker(),
        SizedBox(height: 24.0),
        _buildLocationPicker(),
        SizedBox(height: 24.0),
        _buildCreateGroupButton(),
      ],
    );
  }

  Widget _buildGroupImagePicker() {
    return _groupImageUrl == null
        ? Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(border: Border.all()),
            child: Icon(Icons.add_a_photo, size: 50),
          )
        : Image.network(
            _groupImageUrl!,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          );
  }

  Widget _buildGroupDetailsForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          decoration: InputDecoration(labelText: 'Group Description'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a group description';
            }
            return null;
          },
        ),
        SizedBox(height: 16.0),
        _buildGroupSizeDropdown(),
        SizedBox(height: 16.0),
        _buildGroupTypeDropdown(),
      ],
    );
  }

  Widget _buildGroupSizeDropdown() {
    return DropdownButtonFormField<int>(
      value: _groupSize,
      decoration: InputDecoration(labelText: 'Group Size'),
      items: List.generate(9, (index) => index + 2).map((size) {
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
    );
  }

  Widget _buildGroupTypeDropdown() {
    return DropdownButtonFormField<int>(
      value: _groupType,
      decoration: InputDecoration(labelText: 'Group Type'),
      items: [
        DropdownMenuItem<int>(value: 1, child: Text('Type 1')),
        DropdownMenuItem<int>(value: 2, child: Text('Type 2')),
      ],
      onChanged: (value) {
        setState(() {
          _groupType = value!;
        });
      },
    );
  }

  Widget _buildDateTimePicker() {
    return Row(
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
    );
  }

  Widget _buildLocationPicker() {
    return ElevatedButton(
      onPressed: _navigateAndPickLocation,
      child: Text('เลือกสถานที่'),
    );
  }

  Widget _buildCreateGroupButton() {
    return ElevatedButton(
      onPressed: _createGroup,
      child: Text('Create Group'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Group'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildForm(),
        ),
      ),
    );
  }
}
