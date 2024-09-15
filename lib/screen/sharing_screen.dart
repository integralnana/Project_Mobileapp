import 'package:flutter/material.dart';
import 'package:projectapp/model/post_model.dart';

import 'package:projectapp/screen/post_screen.dart';

class SharingScreen extends StatefulWidget {
  @override
  _CommunitySharingPageState createState() => _CommunitySharingPageState();
}

class _CommunitySharingPageState extends State<SharingScreen> {
  // ลิสต์ของโพสต์
  List<Post> posts = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[100],
      appBar: AppBar(
        title: Text('หน้าแชร์ซื้อสินค้า'),
        backgroundColor: Colors.orangeAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              // เปิดหน้าสร้างโพสต์และรอข้อมูลโพสต์ที่ถูกส่งกลับมา
              final newPost = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreatePostScreen()),
              );

              if (newPost != null && newPost is Post) {
                setState(() {
                  // เพิ่มโพสต์ใหม่ในลิสต์
                  posts.add(newPost);
                });
              }
            },
          ),
        ],
      ),
      body: posts.isEmpty
          ? Center(
              child: Text(
                'ยังไม่มีโพสต์',
                style: TextStyle(color: Colors.black, fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.productName,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('จำนวนคนที่เข้าร่วม: ${post.participants} คน'),
                        SizedBox(height: 8),
                        Text('การจ่ายเงิน: ${post.paymentType}'),
                        SizedBox(height: 8),
                        Text('รายละเอียด: ${post.description}'),
                        SizedBox(height: 8),
                        Text('ประเภทสินค้า: ${post.category}'),
                        SizedBox(height: 8),
                        Text('เวลารับสินค้า: ${post.pickUpTime}'),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
