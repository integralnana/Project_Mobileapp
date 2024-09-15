import 'package:flutter/material.dart';
import 'package:projectapp/screen/post_screen.dart';

// สร้าง Post class เพื่อเก็บข้อมูลโพสต์
class Post {
  final String userName;
  final double rating;
  final String productName;
  final int people;
  final String category;
  final String imagePath;
  final String description;
  final String availability;
  final String payment;
  final String pickupTime;

  Post({
    required this.userName,
    required this.rating,
    required this.productName,
    required this.people,
    required this.category,
    required this.imagePath,
    required this.description,
    required this.availability,
    required this.payment,
    required this.pickupTime,
  });
}

// สมมุติว่ามีการดึงข้อมูลโพสต์จากฐานข้อมูล
final List<Post> posts = [
  Post(
    userName: 'Jaktorn S.',
    rating: 4.5,
    productName: 'คริมกันแดดและครีมแต้มสิว',
    people: 3,
    category: 'อาหารเสริมและความงาม',
    imagePath: 'assets/your_image_path1.png', // Replace with actual path
    description:
        'หาคนแชร์คริมกันแดดทามอร์ส ยูนิท กับ ครีมแต้มสิวแถมเนื้อย่างละ 1 นิดรับแถววง',
    availability: '1/3',
    payment: 'โอนก่อน',
    pickupTime: 'วันศุกร์, 14 มิถุนายน 2567\n10:00 น.',
  ),
  Post(
    userName: 'Nawaphol S.',
    rating: 4.3,
    productName: 'บุฟเฟ่ต์โออิชิ',
    people: 4,
    category: 'อาหาร',
    imagePath: 'assets/your_image_path2.png', // Replace with actual path
    description: 'หาคนหารบุฟเฟต์โออิชิ ไปกินวันที่ 15 มิถุนายน สามที่สองบ่าย 3',
    availability: '4/4',
    payment: 'จ่ายหลังนัดรับ',
    pickupTime: 'วันเสาร์, 15 มิถุนายน 2567\n15:00 น.',
  ),
];

// หน้าจอหลักสำหรับแชร์ซื้อสินค้า
class SharingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CommunitySharingPage(),
    );
  }
}

class CommunitySharingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('หน้าแชร์ซื้อสินค้า'),
        backgroundColor: Colors.amber,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // เปิดหน้าสร้างโพสต์
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreatePostScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return buildProductCard(
            context,
            post.userName,
            post.rating,
            post.productName,
            post.people,
            post.category,
            post.imagePath,
            post.description,
            post.availability,
            post.payment,
            post.pickupTime,
          );
        },
      ),
    );
  }

  Widget buildProductCard(
    BuildContext context,
    String userName,
    double rating,
    String productName,
    int people,
    String category,
    String imagePath,
    String description,
    String availability,
    String payment,
    String pickupTime,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Icon(Icons.person),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        Text(rating.toString()),
                      ],
                    ),
                  ],
                ),
                Spacer(),
                Text(availability,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 10),
                Icon(Icons.group),
              ],
            ),
            SizedBox(height: 10),
            Image.asset(imagePath,
                height: 100), // แทนที่ด้วย Widget สำหรับรูปภาพ
            SizedBox(height: 10),
            Text(description),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {},
              child: Text(category),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: Text('ดูสถานที่นัดรับ'),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(payment, style: TextStyle(color: Colors.red)),
                    Text(pickupTime, textAlign: TextAlign.right),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// หน้าสร้างโพสต์ (CreatePostScreen)
class CreatePostScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('หน้าสร้างโพสต์'),
        backgroundColor: Colors.amber,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('หัวข้อ/ชื่อสินค้า'),
            TextField(
              decoration: InputDecoration(
                hintText: 'กรอกชื่อสินค้า',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            Text('จำนวนคนที่เข้าร่วม'),
            DropdownButtonFormField(
              items: [2, 3, 4]
                  .map((number) => DropdownMenuItem(
                        value: number,
                        child: Text('$number คน'),
                      ))
                  .toList(),
              onChanged: (value) {},
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            Text('ประเภทการจ่ายเงิน'),
            DropdownButtonFormField(
              items: ['จ่ายหลังนัดรับ', 'โอนก่อน']
                  .map((method) => DropdownMenuItem(
                        value: method,
                        child: Text(method),
                      ))
                  .toList(),
              onChanged: (value) {},
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            Text('รายละเอียดสินค้า'),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'กรอกรายละเอียดสินค้า',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            Text('ประเภทสินค้า'),
            DropdownButtonFormField(
              items: ['อาหาร', 'อาหารเสริมและความงาม']
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) {},
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            Text('วันและเวลานัดรับ'),
            TextField(
              decoration: InputDecoration(
                hintText: 'กรอกวันและเวลา',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // โค้ดสำหรับส่งข้อมูลโพสต์ไปยังฐานข้อมูล
              },
              child: Text('สร้างโพสต์'),
            ),
          ],
        ),
      ),
    );
  }
}
