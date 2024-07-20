import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class VipSubScreen extends StatefulWidget {
  @override
  _VipSubScreenState createState() => _VipSubScreenState();
}

class _VipSubScreenState extends State<VipSubScreen> {
  File? _image;
  final picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

// อันนี้ให้แชทลองเขียนวิธีส่งรูปไปที่อีเมล มันบอกให้ใช้ firebase
  Future<void> _uploadAndSendEmail() async {
    if (_image == null) return;

    try {
      // Placeholder for uploading the image to Firebase Storage
      // String fileName = 'uploads/${DateTime.now().millisecondsSinceEpoch}.jpg';
      // Reference ref = FirebaseStorage.instance.ref().child(fileName);
      // await ref.putFile(_image!);
      // String downloadUrl = await ref.getDownloadURL();

      // Placeholder for calling Firebase Function to send email
      // HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('sendEmailWithAttachment');
      // final results = await callable.call(<String, dynamic>{
      //   'email': 'recipient@example.com',
      //   'attachmentUrl': downloadUrl,
      // });

      // Uncomment the below lines after integrating with Firebase
      // if (results.data['success']) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Email sent successfully!')),
      //   );
      // } else {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Failed to send email: ${results.data['error']}')),
      //   );
      // }

      // Temporary message to indicate function completion
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Upload and email functionality not implemented yet.')),
      );
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image and send email.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[100],
      appBar: AppBar(
        title: Text('สมัครVIP'),
        backgroundColor: Colors.amber,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Spacer(flex: 1),
            Center(
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Image.asset(
                  'assets/images/QR.jpg',
                  height: 250,
                ),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'แพคเกจ 1 เดือน : 100 บาท',
                style: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'โปรดส่งสลิปหลังชำระเงิน',
                style: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              flex: 2,
              child: Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black),
                    ),
                    child: _image == null
                        ? Icon(
                            Icons.add,
                            size: 50,
                            color: Colors.black,
                          )
                        : Image.file(
                            _image!,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _uploadAndSendEmail,
                child: Text('ยืนยันการสมัครสมาชิก'),
              ),
            ),
            Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}
