import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projectapp/screen/report.dart';

class ProfileScreen extends StatefulWidget {
  final String fname;
  final String lname;
  final String imageUrl;

  ProfileScreen({
    required this.fname,
    required this.lname,
    required this.imageUrl,
  });
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double _averageRating = 0;
  int _reviewCount = 0;

  void _updateRatings(double rating) {
    setState(() {
      _reviewCount += 1;
      _averageRating =
          ((_averageRating * (_reviewCount - 1)) + rating) / _reviewCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
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
              ProfileHeader(
                averageRating: _averageRating,
                fname: widget.fname,
                lname: widget.lname,
                imageUrl: widget.imageUrl,
              ),
              SizedBox(height: 16),
              ProfileStats(),
              SizedBox(height: 16),
              Expanded(child: ReviewSection(onRatingChanged: _updateRatings)),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  final String fname;
  final String lname;
  final String imageUrl;
  final double averageRating;

  ProfileHeader(
      {required this.fname,
      required this.lname,
      required this.imageUrl,
      required this.averageRating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage:
                imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
            child: imageUrl.isEmpty ? Icon(Icons.person, size: 50) : null,
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fname + " " + lname[0] + ".",
                style: GoogleFonts.anuphan(
                    fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 24),
                  SizedBox(width: 4),
                  Text(
                    '${averageRating.toStringAsFixed(1)}/5',
                    style: GoogleFonts.anuphan(fontSize: 18),
                  ),
                ],
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
                backgroundColor: const Color.fromARGB(255, 255, 255, 255)),
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
    );
  }
}

class ProfileStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ความสำเร็จในการร่วมแชร์ซื้อสินค้า : 15',
            style: GoogleFonts.anuphan(fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class ReviewSection extends StatefulWidget {
  final Function(double) onRatingChanged;

  ReviewSection({required this.onRatingChanged});

  @override
  _ReviewSectionState createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<ReviewSection> {
  final TextEditingController _controller = TextEditingController();
  final List<ReviewItem> _reviews = [];
  int _selectedRating = 5;

  void _addReview(String reviewText, int rating) {
    setState(() {
      _reviews.add(ReviewItem(reviewText: reviewText, rating: rating));
    });
    widget.onRatingChanged(rating.toDouble());
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'รีวิว',
          style: GoogleFonts.anuphan(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _reviews.length,
            itemBuilder: (context, index) {
              return _reviews[index];
            },
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'เขียนรีวิว...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            DropdownButton<int>(
              value: _selectedRating,
              items: List.generate(5, (index) => index + 1)
                  .map((rating) => DropdownMenuItem<int>(
                        value: rating,
                        child: Text('$rating ดาว'),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRating = value!;
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.send),
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  _addReview(_controller.text, _selectedRating);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

class ReviewItem extends StatelessWidget {
  final String reviewText;
  final int rating;

  ReviewItem({required this.reviewText, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.person, size: 40, color: Colors.black),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(
                    rating,
                    (index) => Icon(Icons.star, color: Colors.amber, size: 20),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  reviewText,
                  style: GoogleFonts.anuphan(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
