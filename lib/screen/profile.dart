import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projectapp/constant.dart';
import 'package:projectapp/screen/report.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  ProfileScreen({
    required this.userId,
  });

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _fname = '';
  String _lname = '';
  String _imageUrl = '';
  String _username = '';
  int _point = 0;
  double _reviewRating = 0.0;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        // Query reviews from the top-level reviews collection
        QuerySnapshot reviewsSnapshot = await FirebaseFirestore.instance
            .collection('reviews')
            .where('userId', isEqualTo: widget.userId)
            .get();

        setState(() {
          _fname = userDoc['fname'] ?? '';
          _lname = userDoc['lname'] ?? '';
          _imageUrl = userDoc['imageUrl'] ?? '';
          _username = userDoc['username'] ?? '';
          _point = userDoc['point'] ?? 0;
          _reviewRating =
              reviewsSnapshot.size > 0 ? _point / reviewsSnapshot.size : 0.0;
        });
      }
      print(_point);
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarColor,
        title: Text('โปรไฟล์', style: GoogleFonts.anuphan()),
        centerTitle: true,
        actions: [
          if (widget.userId != FirebaseAuth.instance.currentUser?.uid)
            IconButton(
              icon: Icon(
                Icons.flag_circle,
                size: 35,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportScreen(
                      userId: FirebaseAuth.instance.currentUser!.uid,
                      reportToId: widget.userId,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            SizedBox(height: 16),
            _buildToggleButtons(),
            SizedBox(height: 16),
            Expanded(
              child:
                  _selectedIndex == 0 ? _buildReviewList() : _buildGroupList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        _buildProfileImage(),
        SizedBox(width: 16),
        _buildProfileInfo(),
      ],
    );
  }

  Widget _buildProfileImage() {
    return CircleAvatar(
      radius: 35,
      backgroundImage: _imageUrl.isNotEmpty ? NetworkImage(_imageUrl) : null,
      child: _imageUrl.isEmpty ? Icon(Icons.person, size: 50) : null,
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _username,
          style: GoogleFonts.anuphan(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '$_fname ${_lname.isNotEmpty ? _lname[0] + '.' : ''}',
          style: GoogleFonts.anuphan(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        _buildReviewRating(),
      ],
    );
  }

  Widget _buildReviewRating() {
    return Row(
      children: [
        Icon(
          Icons.star,
          color: Colors.amber,
        ),
        Text(
          _reviewRating.toStringAsFixed(1),
          style: GoogleFonts.anuphan(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('userId', isEqualTo: widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ประวัติการรีวิว',
                style: GoogleFonts.anuphan(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: snapshot.data?.docs.length,
                  itemBuilder: (context, index) =>
                      _buildReviewItem(snapshot.data!.docs[index]),
                ),
              ),
            ],
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error loading reviews'),
          );
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  Widget _buildReviewItem(DocumentSnapshot reviewDoc) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(reviewDoc['reviewerId'])
          .get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.hasData) {
          return Container(
            margin: EdgeInsets.only(bottom: 5),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppTheme.cardColor),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(userSnapshot.data!['imageUrl']),
                radius: 30,
              ),
              title: Row(
                children: [
                  Text(
                    userSnapshot.data!['username'],
                    style: GoogleFonts.anuphan(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRatingStars(reviewDoc['star']),
                  SizedBox(height: 4),
                  Text(
                    reviewDoc['comment'],
                    style: GoogleFonts.anuphan(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('groups')
                        .doc(reviewDoc['groupId'])
                        .get(),
                    builder: (context, groupSnapshot) {
                      if (groupSnapshot.hasData && groupSnapshot.data!.exists) {
                        return Text(
                          'กลุ่ม: ${groupSnapshot.data!['groupName']}',
                          style: GoogleFonts.anuphan(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          );
        } else {
          return Container();
        }
      },
    );
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      children: [
        for (int i = 0; i < rating; i++)
          Icon(
            Icons.star,
            color: Colors.amber,
            size: 18,
          ),
        if (rating < 5)
          for (int i = 0; i < 5 - rating; i++)
            Icon(
              Icons.star_border,
              color: Colors.amber,
              size: 18,
            ),
      ],
    );
  }

  Widget _buildToggleButtons() {
    return Center(
      child: ToggleButtons(
        isSelected: [_selectedIndex == 0, _selectedIndex == 1],
        onPressed: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(8),
        selectedColor: Colors.white,
        fillColor: AppTheme.buttonColor,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'ประวัติการรีวิว',
              style: GoogleFonts.anuphan(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'ประวัติการเข้าร่วม',
              style: GoogleFonts.anuphan(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupList() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('groups')
          .where('groupStatus', isEqualTo: 4)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<Widget> groupItems = [];
          for (var groupDoc in snapshot.data!.docs) {
            groupItems.add(
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('groups')
                    .doc(groupDoc.id)
                    .collection('userlist')
                    .doc(widget.userId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    return _buildGroupItem(groupDoc);
                  }
                  return SizedBox.shrink();
                },
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ประวัติการเข้าร่วม',
                style: GoogleFonts.anuphan(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: groupItems,
                ),
              ),
            ],
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text('เกิดข้อผิดพลาดขณะโหลดข้อมูลกลุ่ม'),
          );
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  Widget _buildGroupItem(DocumentSnapshot groupDoc) {
    return Container(
      margin: EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10), color: AppTheme.cardColor),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage('${groupDoc['groupImage']}'),
          radius: 32,
        ),
        title: Text(
          groupDoc['groupName'],
          style: GoogleFonts.anuphan(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          groupDoc['groupCate'],
          style: GoogleFonts.anuphan(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }
}
