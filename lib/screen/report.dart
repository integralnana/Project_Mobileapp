import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:projectapp/constant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;

class ReportScreen extends StatefulWidget {
  final String userId;

  const ReportScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final List<Map<String, dynamic>> reportTypes = [
    {'icon': Icons.warning, 'label': 'แชทคุกคาม'},
    {'icon': Icons.warning, 'label': 'ฉ้อโกง'},
    {
      'icon': Icons.local_shipping_outlined,
      'label': 'ไม่ยอมรับสินค้าหรือไม่ส่งสินค้า'
    },
    {'icon': Icons.report_problem, 'label': 'โพสต์ไม่เหมาะสม'},
    {'icon': Icons.more_horiz, 'label': 'อื่นๆ'},
  ];

  Map<String, bool> selectedReportTypes = {
    'แชทคุกคาม': false,
    'ฉ้อโกง': false,
    'ไม่ยอมรับสินค้าหรือไม่ส่งสินค้า': false,
    'โพสต์ไม่เหมาะสม': false,
    'อื่นๆ': false
  };

  File? _image;
  final TextEditingController _detailsController = TextEditingController();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_image == null) return null;

    try {
      // สร้างชื่อไฟล์ที่ไม่ซ้ำกัน
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(_image!.path)}';

      // อ้างอิงไปยัง Firebase Storage
      final storageRef =
          FirebaseStorage.instance.ref().child('reportImages').child(fileName);

      // อัพโหลดไฟล์
      await storageRef.putFile(_image!);

      // รับ URL ของรูปภาพ
      final imageUrl = await storageRef.getDownloadURL();
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  Future<void> _createReport() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // หา reportType ที่ถูกเลือก
    String selectedType = '';
    selectedReportTypes.forEach((key, value) {
      if (value) selectedType = key;
    });

    // อัพโหลดรูปภาพถ้ามี
    String? imageUrl;
    if (_image != null) {
      imageUrl = await _uploadImage();
    }

    // สร้าง report document ใน subcollection
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('reports')
        .add({
      'reporterId': currentUser.uid,
      'reportType': selectedType,
      'reportDesc': _detailsController.text,
      'imageUrl': imageUrl, // เพิ่ม URL รูปภาพ (null ถ้าไม่มีรูป)
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  Future<void> _submitReport() async {
    if (!selectedReportTypes.containsValue(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกประเภทการรายงาน'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _createReport();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ส่งรายงานเรียบร้อยแล้ว'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'รายงานผู้ใช้งาน',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.amber,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ประเภทการรายงาน',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: reportTypes.map((type) {
                  return FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          type['icon'] as IconData,
                          size: 18,
                          color: selectedReportTypes[type['label']]!
                              ? Colors.white
                              : Colors.amber,
                        ),
                        const SizedBox(width: 8),
                        Text(type['label'] as String),
                      ],
                    ),
                    selected: selectedReportTypes[type['label']]!,
                    onSelected: (bool selected) {
                      setState(() {
                        selectedReportTypes.forEach((key, value) {
                          selectedReportTypes[key] = false;
                        });
                        selectedReportTypes[type['label'] as String] = selected;
                      });
                    },
                    selectedColor: Colors.amber,
                    checkmarkColor: Colors.white,
                    backgroundColor: Colors.grey[200],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.3),
                  ),
                ),
                child: const Text(
                  'โปรดแนบรูปหลักฐานและกรอกรายละเอียดเพื่อให้ง่ายต่อการพิจารณาผู้ใช้งานที่กระทำผิด',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DottedBorder(
                      borderType: BorderType.RRect,
                      radius: const Radius.circular(12),
                      color: Colors.amber,
                      strokeWidth: 2,
                      dashPattern: const [6, 3],
                      child: _image == null
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 40,
                                    color: Colors.amber,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'เพิ่มรูปภาพ',
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _image!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _detailsController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'กรอกรายละเอียดเพิ่มเติม...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.amber),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.amber, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  fillColor: Colors.grey[50],
                  filled: true,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text(
                          'ส่งรายงาน',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
