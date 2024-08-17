import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projectapp/screen/Vip.dart';
import 'package:projectapp/screen/login.dart';
import 'package:projectapp/screen/profile.dart';
import 'package:projectapp/screen/sharing_screen.dart';

class HomeScreen extends StatelessWidget {
  final String email;
  final String password;
  final String fname;
  final String lname;
  final String phone;
  final String imageUrl;

  HomeScreen(
      {Key? key,
      required this.email,
      required this.password,
      required this.fname,
      required this.lname,
      required this.phone,
      required this.imageUrl})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.pink[100],
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent,
        leading: IconButton(
          icon: const Icon(Icons.person),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.orangeAccent,
              ),
              child: Column(
                children: [
                  Text(
                    '$fname ${lname[0]}.',
                    style: GoogleFonts.anuphan(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                    child:
                        imageUrl.isEmpty ? Icon(Icons.person, size: 50) : null,
                  ),
                ],
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
                            fname: fname,
                            lname: lname,
                            imageUrl: imageUrl,
                          )),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.diamond),
              title: Text('สมัคร VIP', style: GoogleFonts.anuphan()),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VipSubScreen()),
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
                onPressed: () {},
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
