// chat_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('หน้าแสดงแชท',
            style:
                GoogleFonts.anuphan(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orangeAccent,
      ),
      backgroundColor: Colors.pink[100],
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          // Chat item 1
          Container(
            margin: EdgeInsets.symmetric(vertical: 8.0),
            padding: EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ครีมกันแดดและครีมแต้มสิว : กำลังขอเข้าร่วม',
                  style: GoogleFonts.anuphan(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('ผู้โพสต์ : Jaktorn S.', style: GoogleFonts.anuphan()),
              ],
            ),
          ),
          // Chat item 2
          Container(
            margin: EdgeInsets.symmetric(vertical: 8.0),
            padding: EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'บุฟเฟต์โออิชิ : ยอมรับแล้ว',
                  style: GoogleFonts.anuphan(
                      fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 4),
                Text('สถานะ : กำลังดำเนินการซื้อ',
                    style: GoogleFonts.anuphan()),
                const SizedBox(height: 4),
                Text('ผู้โพสต์ : Nawaphol S.', style: GoogleFonts.anuphan()),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Implement chat functionality here
                    },
                    icon: Icon(Icons.chat_bubble),
                    label: Text('แชท', style: GoogleFonts.anuphan()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Add more chat items here...
        ],
      ),
    );
  }
}
