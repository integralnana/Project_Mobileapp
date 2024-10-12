import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // นำเข้า Firebase Auth
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projectapp/screen/report.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _fname = '';
  String _lname = '';
  String _imageUrl = '';
  String _username = '';
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          _fname = userDoc['fname'] ?? '';
          _lname = userDoc['lname'] ?? '';
          _imageUrl = userDoc['imageUrl'] ?? '';
          _username = userDoc['username'] ?? '';
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: Text('โปรไฟล์', style: GoogleFonts.anuphan()),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Show the profile image
                CircleAvatar(
                  radius: 40,
                  backgroundImage:
                      _imageUrl.isNotEmpty ? NetworkImage(_imageUrl) : null,
                  child:
                      _imageUrl.isEmpty ? Icon(Icons.person, size: 50) : null,
                ),
                SizedBox(width: 16),
                // Display username and full name
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _username,
                      style: GoogleFonts.anuphan(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _fname + (_lname.isNotEmpty ? " " + _lname[0] + "." : ""),
                      style: GoogleFonts.anuphan(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Spacer(),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ReportScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color.fromARGB(255, 255, 255, 255)),
                  child: Row(
                    children: [
                      Text('รายงาน', style: GoogleFonts.anuphan()),
                      SizedBox(width: 4),
                      Icon(Icons.flag),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'ความสำเร็จในการร่วมแชร์ซื้อสินค้า : 15',
              style: GoogleFonts.anuphan(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
