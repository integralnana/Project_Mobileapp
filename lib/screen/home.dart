import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projectapp/screen/login.dart';
import 'package:projectapp/screen/person.dart';
import 'package:projectapp/screen/register.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Register/Login"),
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(10, 90, 10, 0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Image.asset("assets/images/kuromi.jpg"),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) {
                          return RegisterScreen();
                        }),
                      );
                    },
                    icon: Icon(Icons.add),
                    label: Text("สมัครสมาชิก", style: GoogleFonts.anuphan()),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) {
                          return LoginScreen();
                        }),
                      );
                    },
                    icon: Icon(Icons.login),
                    label: Text("ล็อกอิน", style: GoogleFonts.anuphan()),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) {
                          return PersonScreen();
                        }),
                      );
                    },
                    icon: Icon(Icons.add),
                    label: Text("ประเทภบุคคล", style: GoogleFonts.anuphan()),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
