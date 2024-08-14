import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projectapp/screen/home.dart';
import 'package:projectapp/screen/person.dart';
import 'package:projectapp/screen/register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  final Future<FirebaseApp> firebase = Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyBO3VQD8fjFxezDPJYY8FSmZxrm_WMSmBU',
      appId: '1:163897380043:android:ad7b0effe0942c72a79f4e',
      messagingSenderId: '163897380043',
      projectId: 'myproj-c6008',
      storageBucket: "myproj-c6008.appspot.com",
    ),
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: firebase,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Error"),
            ),
            body: Center(
              child: Text("${snapshot.error}"),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.done) {
          return Scaffold(
            backgroundColor: Colors.pink[100],
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'ยินดีต้อนรับ',
                          style: GoogleFonts.anuphan(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'กรุณาเข้าสู่ระบบ',
                          style: GoogleFonts.anuphan(
                            fontSize: 18,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text("อีเมล", style: GoogleFonts.anuphan()),
                        ),
                        TextFormField(
                          validator: MultiValidator([
                            RequiredValidator(errorText: "กรุณากรอกอีเมล"),
                            EmailValidator(errorText: "รูปแบบอีเมลไม่ถูกต้อง"),
                          ]),
                          onSaved: (value) {
                            email = value!;
                          },
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'กรุณากรอกชื่อผู้ใช้งาน',
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
                          child: Text("รหัสผ่าน", style: GoogleFonts.anuphan()),
                        ),
                        TextFormField(
                          validator:
                              RequiredValidator(errorText: "กรุณากรอกรหัสผ่าน"),
                          onSaved: (value) {
                            password = value!;
                          },
                          obscureText: true,
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
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              formKey.currentState?.save();
                              try {
                                await FirebaseAuth.instance
                                    .signInWithEmailAndPassword(
                                  email: email,
                                  password: password,
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const HomeScreen()),
                                );
                              } on FirebaseAuthException catch (e) {
                                print(e.message);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'ล็อกอิน',
                            style: GoogleFonts.anuphan(
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'ลืมรหัสผ่าน',
                            style: GoogleFonts.anuphan(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) {
                                return PersonScreen();
                              }),
                            );
                          },
                          child: Text(
                            'สมัครสมาชิก',
                            style: GoogleFonts.anuphan(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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

        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
