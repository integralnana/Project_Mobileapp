import 'package:flutter/material.dart';

void main() {
  runApp(SharingScreen());
}

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
              // Add your logic here
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          buildProductCard(
            context,
            'Jaktorn S.',
            4.5,
            'คริมกันแดดและครีมแต้มสิว',
            3,
            'อาหารเสริมและความงาม',
            'assets/your_image_path1.png', // Replace with your image asset path
            'รายละเอียด',
            '1/3',
            'โอนก่อน',
            'วันศุกร์, 14 มิถุนายน 2567\n10:00 น.',
          ),
          buildProductCard(
            context,
            'Nawaphol S.',
            4.3,
            'บุฟเฟ่ต์โออิชิ',
            4,
            'อาหาร',
            'assets/your_image_path2.png', // Replace with your image asset path
            'รายละเอียด',
            '4/4',
            'จ่ายหลังนัดรับ',
            'วันเสาร์, 15 มิถุนายน 2567\n15:00 น.',
          ),
        ],
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
                height: 100), // Replace with your image widget
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
