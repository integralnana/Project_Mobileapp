import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// ที่คอมเม้นไว้คือส่วนที่เชื่อมกับ firebase ให้ chat ลองเขียนให้

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase here
  // await Firebase.initializeApp();
  runApp(ReportScreen());
}

class ReportScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ReportPage(),
    );
  }
}

class ReportPage extends StatefulWidget {
  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  List<String> reportTypes = [
    'แชทคุกคาม',
    'ฉ่อโกง',
    'ไม่ยอมรับสินค้าหรือไม่ส่งสินค้า',
    'โพสต์ไม่เหมาะสม',
    'อื่นๆ'
  ];

  Map<String, bool> selectedReportTypes = {
    'แชทคุกคาม': false,
    'ฉ่อโกง': false,
    'ไม่ยอมรับสินค้าหรือไม่ส่งสินค้า': false,
    'โพสต์ไม่เหมาะสม': false,
    'อื่นๆ': false
  };

  File? _image;

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    try {
      // Upload image to Firebase Storage
      //String fileName = 'images/${DateTime.now().millisecondsSinceEpoch}.png';
      // Replace the following line with actual Firebase Storage upload code
      // await FirebaseStorage.instance.ref(fileName).putFile(_image!);

      // Get the download URL of the uploaded image
      // String downloadURL = await FirebaseStorage.instance.ref(fileName).getDownloadURL();

      // Save report details to Firestore
      // Replace the following line with actual Firestore upload code
      // await FirebaseFirestore.instance.collection('reports').add({
      //   'image_url': downloadURL,
      //   'report_types': selectedReportTypes.keys.where((type) => selectedReportTypes[type]!).toList(),
      //   'details': _detailsController.text,
      //   'timestamp': FieldValue.serverTimestamp(),
      // });

      // Print success message
      print('Upload successful. Download URL: ');
    } catch (e) {
      print('Upload failed: $e');
    }
  }

  final TextEditingController _detailsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายงานผู้ใช้งาน'),
        backgroundColor: Colors.amber,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ระบุประเภท',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: reportTypes.map((type) {
                return FilterChip(
                  label: Text(type),
                  selected: selectedReportTypes[type]!,
                  onSelected: (bool selected) {
                    setState(() {
                      selectedReportTypes[type] = selected;
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            Text(
              'โปรดแนบรูปหลักฐานและกรอกรายละเอียดเพื่อให้ง่ายต่อการพิจารณาผู้ใช้งานที่กระทำผิด',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _image == null
                      ? Icon(Icons.add_photo_alternate,
                          size: 50, color: Colors.grey)
                      : Image.file(_image!),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _detailsController,
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'รายละเอียด',
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _uploadImage,
                child: Text('รายงานผู้ใช้งาน'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
