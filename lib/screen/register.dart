// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:form_field_validator/form_field_validator.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:projectapp/model/profile.dart';
// import 'package:projectapp/screen/login.dart';

// class RegisterScreen extends StatefulWidget {
//   const RegisterScreen({super.key});

//   @override
//   State<RegisterScreen> createState() => _RegisterScreenState();
// }

// class _RegisterScreenState extends State<RegisterScreen> {
//   final formkey = GlobalKey<FormState>();
//   Profile profile = Profile(email: '', password: '', userId: '', userTel: '');
//   final Future<FirebaseApp> firebase = Firebase.initializeApp(
//       options: FirebaseOptions(
//           apiKey: 'AIzaSyBO3VQD8fjFxezDPJYY8FSmZxrm_WMSmBU',
//           appId: '1:163897380043:android:ad7b0effe0942c72a79f4e',
//           messagingSenderId: '163897380043',
//           projectId: 'myproj-c6008'));

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder(
//       future: firebase,
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return Scaffold(
//               appBar: AppBar(
//                 title: Text("Error"),
//               ),
//               body: Center(
//                 child: Text("${snapshot.error}"),
//               ));
//         }
//         if (snapshot.connectionState == ConnectionState.done) {
//           return Scaffold(
//             backgroundColor: Colors.pink[100],
//             body: Center(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 32.0),
//                 child: SingleChildScrollView(
//                   child: Form(
//                     key: formkey,
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         const SizedBox(height: 40),
//                         const Text(
//                           'สมัครสมาชิก',
//                           style: TextStyle(
//                             fontSize: 32,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.black,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 40),
//                         Align(
//                           alignment: Alignment.centerLeft,
//                           child: Text("อีเมล", style: GoogleFonts.anuphan()),
//                         ),
//                         TextFormField(
//                           validator: MultiValidator([
//                             RequiredValidator(errorText: "กรุณากรอกอีเมล"),
//                             EmailValidator(errorText: "รูปแบบอีเมลไม่ถูกต้อง"),
//                           ]),
//                           onSaved: (email) {
//                             profile.email = email!;
//                           },
//                           keyboardType: TextInputType.emailAddress,
//                           decoration: InputDecoration(
//                             hintText: 'อีเมล',
//                             filled: true,
//                             fillColor: Colors.white,
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(25.0),
//                               borderSide: BorderSide.none,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 15),
//                         Align(
//                           alignment: Alignment.centerLeft,
//                           child: Text("รหัสผ่าน", style: GoogleFonts.anuphan()),
//                         ),
//                         TextFormField(
//                           validator:
//                               RequiredValidator(errorText: "กรุณากรอกรหัสผ่าน"),
//                           onSaved: (password) {
//                             profile.password = password!;
//                           },
//                           obscureText: true,
//                           decoration: InputDecoration(
//                             hintText: 'รหัสผ่าน',
//                             filled: true,
//                             fillColor: Colors.white,
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(25.0),
//                               borderSide: BorderSide.none,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 15),
//                         Align(
//                           alignment: Alignment.centerLeft,
//                           child: Text("เบอร์โทร", style: GoogleFonts.anuphan()),
//                         ),
//                         TextFormField(
//                           validator:
//                               RequiredValidator(errorText: "กรุณากรอกเบอร์โทร"),
//                           onSaved: (userTel) {
//                             profile.userTel = userTel!;
//                           },
//                           keyboardType: TextInputType.phone,
//                           decoration: InputDecoration(
//                             hintText: 'เบอร์โทร',
//                             filled: true,
//                             fillColor: Colors.white,
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(25.0),
//                               borderSide: BorderSide.none,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 40),
//                         SizedBox(
//                           width: double.infinity,
//                           child: ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.blue[300],
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(25.0),
//                               ),
//                               padding: const EdgeInsets.symmetric(vertical: 16),
//                             ),
//                             child: const Text(
//                               "เสร็จสิ้น",
//                               style: TextStyle(fontSize: 18),
//                             ),
//                             onPressed: () async {
//                               if (formkey.currentState!.validate()) {
//                                 formkey.currentState?.save();
//                                 try {
//                                   await FirebaseAuth.instance
//                                       .createUserWithEmailAndPassword(
//                                           email: profile.email,
//                                           password: profile.password);
//                                   formkey.currentState?.reset();
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                         builder: (context) => LoginScreen()),
//                                   );
//                                 } on FirebaseAuthException catch (e) {
//                                   print(e.message);
//                                 }
//                               }
//                             },
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           );
//         }
//         return Scaffold(
//           body: Center(
//             child: CircularProgressIndicator(),
//           ),
//         );
//       },
//     );
//   }
// }

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projectapp/model/profile.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _userNickController = TextEditingController();
  final _studentIdController = TextEditingController();
  String? _userType;
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
          userNick: _userNickController.text,
          studentId: _studentIdController.text,
          userType: _userType ?? "",
          imageUrl: imageUrl,
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(newUser.userId)
            .set(newUser.toMap());

        // แจ้งว่าลงทะเบียนสำเร็จ
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Sign up successful!')));
      } on FirebaseAuthException catch (e) {
        // แสดงข้อผิดพลาด
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'Sign up failed!')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Password must be at least 6 characters long';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: Text('Pick an Image'),
                  ),
                  if (_image != null)
                    Image.file(_image!, height: 100, width: 100),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _signUp,
                    child: Text('Sign Up'),
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
