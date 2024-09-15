// notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('หน้าแจ้งเตือน',
            style:
                GoogleFonts.anuphan(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orangeAccent,
      ),
      backgroundColor: Colors.pink[100],
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          // Example notification card 1
          Container(
            margin: EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.black),
              ),
              title: Text('Nawaphol S.',
                  style: GoogleFonts.anuphan(fontWeight: FontWeight.bold)),
              subtitle: Text('อาหารสุขภาพ : คุณมีคำขอเข้าร่วมแชร์สินค้า'),
              trailing: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text('ตอบรับ'),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text('ปฏิเสธ'),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text('7 นาที', style: GoogleFonts.anuphan(fontSize: 12)),
                ],
              ),
            ),
          ),
          // Example notification card 2
          Container(
            margin: EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: ListTile(
              title: Text('รองเท้อติดลาส',
                  style: GoogleFonts.anuphan(fontWeight: FontWeight.bold)),
              subtitle: Text('คุณมีการนัดรับสินค้าที่จะมาถึง'),
              trailing:
                  Text('14 นาที', style: GoogleFonts.anuphan(fontSize: 12)),
            ),
          ),
          // Add more notifications here...
        ],
      ),
    );
  }
}
