import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projectapp/model/profile.dart';
import 'package:projectapp/screen/home.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _fnameController = TextEditingController();
  final _lnameController = TextEditingController();
  final _usernameController = TextEditingController();
  File? _image;

  Future<void> _pickImage() async {
    final pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
      });
    }
  }

  Future<void> _signUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        String imageUrl = '';
        try {
          if (_image != null) {
            final storageRef = FirebaseStorage.instance
                .ref()
                .child('user_images')
                .child(userCredential.user!.uid + '.jpg');
            await storageRef.putFile(_image!);
            imageUrl = await storageRef.getDownloadURL();
            print('Uploaded image URL: $imageUrl');
          }
        } catch (e) {
          print('Error uploading image: $e');
        }

        Profile newUser = Profile(
          userId: userCredential.user!.uid,
          email: _emailController.text,
          phone: _phoneController.text,
          fname: _fnameController.text,
          lname: _lnameController.text,
          imageUrl: imageUrl,
          username: _usernameController.text,
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(newUser.userId)
            .set(newUser.toMap());

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(),
          ),
        );
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'Sign up failed!')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[100],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'สมัครสมาชิกและสร้างโปรไฟล์ของคุณ',
                    style: GoogleFonts.anuphan(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          _image != null ? FileImage(_image!) : null,
                      backgroundColor: Colors.grey[200],
                      child: _image == null
                          ? const Icon(
                              Icons.camera_alt,
                              size: 50,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Username", style: GoogleFonts.anuphan()),
                  ),
                  TextFormField(
                    validator: MultiValidator([
                      RequiredValidator(errorText: "กรุณากรอก Username"),
                    ]).call,
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: 'กรุณากรอก Username',
                      hintStyle: GoogleFonts.anuphan(),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("อีเมล", style: GoogleFonts.anuphan()),
                  ),
                  TextFormField(
                    validator: MultiValidator([
                      RequiredValidator(errorText: "กรุณากรอกอีเมล"),
                      EmailValidator(errorText: "รูปแบบอีเมลไม่ถูกต้อง"),
                    ]).call,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'กรุณากรอกอีเมล',
                      hintStyle: GoogleFonts.anuphan(),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("รหัสผ่าน", style: GoogleFonts.anuphan()),
                  ),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      hintText: 'กรุณากรอกรหัสผ่าน',
                      hintStyle: GoogleFonts.anuphan(),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'ความยาวของรหัสผ่านต้องมีอย่างน้อย 6 ตัว';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("ชื่อจริง", style: GoogleFonts.anuphan()),
                  ),
                  TextFormField(
                    validator:
                        RequiredValidator(errorText: "กรุณากรอกชื่อจริง"),
                    controller: _fnameController,
                    keyboardType: TextInputType.name,
                    decoration: InputDecoration(
                      hintText: 'กรุณากรอกชื่อจริง',
                      hintStyle: GoogleFonts.anuphan(),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("นามสกุล", style: GoogleFonts.anuphan()),
                  ),
                  TextFormField(
                    validator: RequiredValidator(errorText: "กรุณากรอกนามสกุล"),
                    controller: _lnameController,
                    keyboardType: TextInputType.name,
                    decoration: InputDecoration(
                      hintText: 'กรุณากรอกนามสกุล',
                      hintStyle: GoogleFonts.anuphan(),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("เบอร์โทร", style: GoogleFonts.anuphan()),
                  ),
                  TextFormField(
                    validator:
                        RequiredValidator(errorText: "กรุณากรอกเบอร์โทร"),
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'กรุณากรอกเบอร์โทร',
                      hintStyle: GoogleFonts.anuphan(),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _signUp,
                    child: Text(
                      'สมัครสมาชิก',
                      style: GoogleFonts.anuphan(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
