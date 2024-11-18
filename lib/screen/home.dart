import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projectapp/constant.dart';
import 'package:projectapp/screen/Vip.dart';
import 'package:projectapp/screen/login.dart';
import 'package:projectapp/screen/notification.dart';
import 'package:projectapp/screen/profile.dart';
import 'package:projectapp/screen/settings.dart';
import 'package:projectapp/screen/sharing_screen.dart';
import 'package:projectapp/screen/sharingdisc_screen.dart';
import 'package:projectapp/screen/showchat.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _fname;
  String? _lname;
  String? _username;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _fname = userDoc['fname'];
          _lname = userDoc['lname'];
          _username = userDoc['username'];
          _imageUrl = userDoc['imageUrl'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarColor,
        leading: IconButton(
          icon: const Icon(Icons.person),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ShowChatScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotiScreen()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 225,
              child: DrawerHeader(
                decoration: BoxDecoration(
                  color: AppTheme.appBarColor,
                ),
                child: Column(
                  children: [
                    Column(
                      children: [
                        Text(
                          '$_username',
                          style: GoogleFonts.anuphan(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        Text(
                          _fname != null && _lname != null
                              ? '($_fname ${_lname![0]}.)'
                              : 'กำลังโหลด...',
                          style: GoogleFonts.anuphan(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          _imageUrl != null ? NetworkImage(_imageUrl!) : null,
                      child: _imageUrl == null
                          ? Icon(Icons.person, size: 50)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: Text('โปรไฟล์', style: GoogleFonts.anuphan()),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                          userId: FirebaseAuth.instance.currentUser!.uid)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.diamond),
              title: Text('VIP', style: GoogleFonts.anuphan()),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VipSubScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text('ตั้งค่า', style: GoogleFonts.anuphan()),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text('ออกจากระบบ', style: GoogleFonts.anuphan()),
              onTap: () async {
                try {
                  await FirebaseAuth.instance.signOut();
                  User? user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ออกจากระบบไม่สำเร็จ โปรดลองอีกครั้ง'),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('เกิดข้อผิดพลาด: $e'),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'กรุณาเลือกรายการ',
                style: GoogleFonts.anuphan(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SharingScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'แชร์ชื้อสินค้า',
                  style: GoogleFonts.anuphan(
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SharingDiscScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'สินค้าลดราคา',
                  style: GoogleFonts.anuphan(
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
