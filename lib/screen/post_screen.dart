import 'package:flutter/material.dart';

class CreatePostScreen extends StatefulWidget {
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  String productName = '';
  String productDetails = '';
  String paymentMethod = 'จ่ายหลังนัดรับ';
  String category = 'อาหาร';
  String pickupTime = '17:30 น.';
  String pickupDate = 'วันจันทร์, 17 มิถุนายน 2567';
  int participants = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('หน้าสร้างโพสต์'),
        backgroundColor: Colors.amber,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Image upload (placeholder)
              GestureDetector(
                onTap: () {
                  // เปิดฟังก์ชันอัพโหลดรูปภาพที่นี่
                },
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.add, size: 50, color: Colors.grey),
                ),
              ),
              SizedBox(height: 16),

              // Product Name Field
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'หัวข้อ/ชื่อสินค้า',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกชื่อสินค้า';
                  }
                  return null;
                },
                onSaved: (value) {
                  productName = value ?? '';
                },
              ),
              SizedBox(height: 16),

              // Participants Dropdown
              DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: 'จำนวนคนนัดร่วม',
                  border: OutlineInputBorder(),
                ),
                value: participants,
                onChanged: (newValue) {
                  setState(() {
                    participants = newValue!;
                  });
                },
                items: List.generate(10, (index) => index + 1)
                    .map<DropdownMenuItem<int>>((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value คน'),
                  );
                }).toList(),
              ),
              SizedBox(height: 16),

              // Payment Method Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'ประเภทการจ่ายเงิน',
                  border: OutlineInputBorder(),
                ),
                value: paymentMethod,
                onChanged: (newValue) {
                  setState(() {
                    paymentMethod = newValue!;
                  });
                },
                items: <String>['จ่ายหลังนัดรับ', 'โอนก่อน']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              SizedBox(height: 16),

              // Product Details Field
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'รายละเอียดสินค้า',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกรายละเอียดสินค้า';
                  }
                  return null;
                },
                onSaved: (value) {
                  productDetails = value ?? '';
                },
              ),
              SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'ประเภทสินค้า',
                  border: OutlineInputBorder(),
                ),
                value: category,
                onChanged: (newValue) {
                  setState(() {
                    category = newValue!;
                  });
                },
                items: <String>[
                  'อาหาร',
                  'เสื้อผ้าและแฟชั่น',
                  'เครื่องใช้ไฟฟ้า',
                  'อาหารเสริมและความงาม'
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              SizedBox(height: 16),

              // Pickup Time and Location
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // เปิดฟังก์ชันตั้งสถานที่นัดรับที่นี่
                      },
                      icon: Icon(Icons.location_pin),
                      label: Text('ตั้งสถานที่นัดรับ'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'วันและเวลานัดรับ',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: pickupDate,
                      onTap: () {
                        // เปิดฟังก์ชันเลือกวันที่
                      },
                      onSaved: (value) {
                        pickupDate = value ?? '';
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Submit Button
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    // ส่งข้อมูลไปยังฐานข้อมูลที่นี่
                    // ตัวอย่าง: await FirebaseFirestore.instance.collection('posts').add({...});
                    Navigator.pop(context); // กลับไปหน้าแชร์โพสต์
                  }
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
