import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:projectapp/model/post_model.dart'; // สำหรับจัดการวันที่

class CreatePostScreen extends StatefulWidget {
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController productNameController = TextEditingController();
  int participants = 2;
  String paymentType = 'จ่ายหลังนัดรับ';
  final TextEditingController descriptionController = TextEditingController();
  String category = 'อาหาร';
  final TextEditingController pickUpLocationController =
      TextEditingController();
  final TextEditingController pickUpDateTimeController =
      TextEditingController();

  File? image; // เก็บรูปภาพที่เลือก
  final ImagePicker _picker = ImagePicker();

  // ฟังก์ชันสำหรับเลือกรูปภาพ
  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        image = File(pickedFile.path);
      });
    }
  }

  // ฟังก์ชันสำหรับเลือกวันที่
  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        pickUpDateTimeController.text = DateFormat('yMMMMd').format(picked);
      });
    }
  }

  // ฟังก์ชันสำหรับเลือกเวลา
  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        final time = DateFormat('jm')
            .format(DateTime(2020, 1, 1, picked.hour, picked.minute));
        pickUpDateTimeController.text += " $time";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('หน้าสร้างโพสต์'),
        backgroundColor: Colors.amber,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // แสดงรูปภาพที่เลือก
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: image == null
                      ? Center(child: Icon(Icons.add_a_photo))
                      : Image.file(image!, fit: BoxFit.cover),
                ),
              ),
              SizedBox(height: 10),
              Text('หัวข้อ/ชื่อสินค้า'),
              TextField(
                controller: productNameController,
                decoration: InputDecoration(
                  hintText: 'กรอกชื่อสินค้า',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              Text('จำนวนคนที่เข้าร่วม'),
              DropdownButtonFormField<int>(
                value: participants,
                items: [2, 3, 4]
                    .map((number) => DropdownMenuItem(
                          value: number,
                          child: Text('$number คน'),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    participants = value ?? 2;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              Text('ประเภทการจ่ายเงิน'),
              DropdownButtonFormField<String>(
                value: paymentType,
                items: ['จ่ายหลังนัดรับ', 'โอนก่อน']
                    .map((method) => DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    paymentType = value ?? 'จ่ายหลังนัดรับ';
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              Text('รายละเอียดสินค้า'),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'กรอกรายละเอียดสินค้า',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              Text('ประเภทสินค้า'),
              DropdownButtonFormField<String>(
                value: category,
                items: ['อาหาร', 'อาหารเสริมและความงาม']
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    category = value ?? 'อาหาร';
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              Text('สถานที่นัดรับ'),
              TextField(
                controller: pickUpLocationController,
                decoration: InputDecoration(
                  hintText: 'ระบุสถานที่',
                  border: OutlineInputBorder(),
                ),
                // คอมเมนต์โค้ดนี้ไว้ก่อนสำหรับ Google Maps API
                // onTap: () async {
                //   // เรียกใช้ Google Maps API เพื่อเลือกสถานที่
                // },
              ),
              SizedBox(height: 10),
              Text('วันและเวลานัดรับ'),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: pickUpDateTimeController,
                      decoration: InputDecoration(
                        hintText: 'เลือกวันและเวลา',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () {
                      _selectDate(context);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.access_time),
                    onPressed: () {
                      _selectTime(context);
                    },
                  ),
                ],
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  final newPost = Post(
                    productName: productNameController.text,
                    participants: participants,
                    paymentType: paymentType,
                    description: descriptionController.text,
                    category: category,
                    pickUpLocation: pickUpLocationController.text,
                    pickUpTime: pickUpDateTimeController.text,
                    imagePath: image?.path,
                  );
                  Navigator.pop(context, newPost); // ส่งโพสต์กลับไป
                },
                child: Text('สร้างโพสต์'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
