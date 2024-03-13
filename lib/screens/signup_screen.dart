import 'package:flutter/material.dart';
import 'package:flutter_3/widgets/custom_upper_bar.dart';
import 'package:flutter_3/widgets/custom_text_field.dart'; 
import 'package:flutter_3/widgets/custom_button.dart';
import 'package:gap/gap.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121417),
      appBar: CustomUpperBar(
        title: 'Sign Up',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: const Color.fromARGB(255, 255, 255, 255),
          onPressed: () {
            Navigator.pushNamed(context, '/');
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          height: MediaQuery.of(context).size.height,
          width: double.infinity,
          child:   Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[ Column(
                children: <Widget>[
                  const Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      "Create your account",
                      style: TextStyle(fontSize: 24.0, color: Colors.white),
                    ),
                  ),
                  const Gap(40),
                  CustomTextField(
                    hintText: "Email",
                    prefixIcon: Icons.email, controller: null, obscureText: null,
                  ),
                  const Gap(20),
                  CustomTextField(
                    hintText: "Password",
                    prefixIcon: Icons.lock, controller: null, obscureText: null,
                  ),
                  const Gap(20),
                  CustomTextField(
                    hintText: "Confirm Password",
                    prefixIcon: Icons.lock, controller: null, obscureText: null,
                  ),
                  const Gap(40),
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: "By continuing, you agree to the ",
                          style: TextStyle(color: Colors.white54),
                        ),
                        TextSpan(
                          text: "Terms of Use",
                          style: TextStyle(
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(15),
                  CustomButton(
                    text: "Sign up",
                    onPressed: () {
                      Navigator.pushNamed(context, '/mainNavigator');
                    },
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text("Already have an account?",
                      style: TextStyle(color: Colors.white54)),
                  TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(color: Colors.white),
                      ))
                ],
              )
            ],
          ),),
        ),
      
    );
  }
}


// after signing up ,the user should not be able to access any robot unless the admin assigns him a project, and related robots will automatically appear after the admin assigns the user to specific projects.
