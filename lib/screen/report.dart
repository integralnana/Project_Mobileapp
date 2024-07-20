import 'package:flutter/material.dart';

void main() {
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

class ReportPage extends StatelessWidget {
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
              children: [
                Chip(label: Text('แชทคุกคาม')),
                Chip(label: Text('ต่อโกง')),
                Chip(label: Text('อื่นๆ')),
                Chip(label: Text('โพสต์ไม่เหมาะสม')),
                Chip(label: Text('ไม่ยอมรับสินค้าหรือไม่ส่งสินค้า')),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'โปรดแนบรูปหลักฐานและกรอกรายละเอียดเพื่อให้ง่ายต่อการพิจารณาผู้ใช้งานที่กระทำผิด',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: () {
                  // Add your image picker logic here
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.add_photo_alternate,
                      size: 50, color: Colors.grey),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'รายละเอียด',
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Add your report submission logic here
                },
                child: Text('รายงานผู้ใช้งาน'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
