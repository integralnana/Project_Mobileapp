class Post {
  final String productName;
  final int participants;
  final String paymentType;
  final String description;
  final String category;
  final String pickUpTime;
  final String? imagePath; // รูปภาพเป็นออปชัน

  Post({
    required this.productName,
    required this.participants,
    required this.paymentType,
    required this.description,
    required this.category,
    required this.pickUpTime,
    this.imagePath,
    required String pickUpLocation,
  });
}
