import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projectapp/model/profile.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formkey = GlobalKey<FormState>();
  Profile profile = Profile(email: '', password: '', userId: '', userTel: '');
  final Future<FirebaseApp> firebase = Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: 'AIzaSyBO3VQD8fjFxezDPJYY8FSmZxrm_WMSmBU',
          appId: '1:163897380043:android:ad7b0effe0942c72a79f4e',
          messagingSenderId: '163897380043',
          projectId: 'myproj-c6008'));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: firebase,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
              appBar: AppBar(
                title: Text("Error"),
              ),
              body: Center(
                child: Text("${snapshot.error}"),
              ));
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return Scaffold(
              appBar: AppBar(title: Text("สร้างบัญชีผู้ใช้")),
              body: Container(
                  child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 50.0, vertical: 50.0),
                child: Form(
                  key: formkey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text("อีเมล", style: GoogleFonts.anuphan()),
                        ),
                        TextFormField(
                          validator: MultiValidator([
                            RequiredValidator(errorText: "กรุณากรอกอีเมล"),
                            EmailValidator(errorText: "รูปแบบอีเมลไม่ถูกต้อง"),
                          ]),
                          onSaved: (email) {
                            profile.email = email!;
                          },
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.0),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text("รหัสผ่าน", style: GoogleFonts.anuphan()),
                        ),
                        TextFormField(
                          validator:
                              RequiredValidator(errorText: "กรุณากรอกรหัสผ่าน"),
                          onSaved: (password) {
                            profile.password = password!;
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.0),
                            ),
                          ),
                          obscureText: true,
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text("เบอร์โทร", style: GoogleFonts.anuphan()),
                        ),
                        TextFormField(
                          validator:
                              RequiredValidator(errorText: "กรุณากรอกเบอร์โทร"),
                          onSaved: (userTel) {
                            profile.userTel = userTel!;
                          },
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.0),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            child: Text("ลงทะเบียน"),
                            onPressed: () async {
                              if (formkey.currentState!.validate()) {
                                formkey.currentState?.save();
                                try {
                                  await FirebaseAuth.instance
                                      .createUserWithEmailAndPassword(
                                          email: profile.email,
                                          password: profile.password);
                                  formkey.currentState?.reset();
                                } on FirebaseAuthException catch (e) {
                                  print(e.message);
                                }
                              }
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              )));
        }
        return Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
