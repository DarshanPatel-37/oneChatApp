import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/image_picker.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _SelectedImage;
  final TextEditingController _userName = TextEditingController();
  final TextEditingController _emailaddress = TextEditingController();
  final TextEditingController _password = TextEditingController();
  var _isLogin = true;
  var _isAuthanticating = false;

  Future<void> _submit() async {
    var isValid = _formKey.currentState!.validate();
    if (!isValid || !_isLogin && _SelectedImage == null) return;
    try {
      if (_isLogin) {
        final UserCredential userCrediantial =
            await _firebase.signInWithEmailAndPassword(
                email: _emailaddress.text, password: _password.text);
        print(userCrediantial);
        // login state
      } else {
        //signup state
        setState(() {
          _isAuthanticating = true;
        });
        final UserCredential userCrediantial =
            await _firebase.createUserWithEmailAndPassword(
                email: _emailaddress.text, password: _password.text);
        final Reference storeRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${userCrediantial.user!.uid}.jpg');
        await storeRef.putFile(_SelectedImage!);
        final imageUploaded = await storeRef.getDownloadURL();
        print(imageUploaded);
        print('---------------------------before------------------------');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCrediantial.user!.uid)
            .set({
          'userName': _userName.text,
          'email': _emailaddress.text,
          'image_url': imageUploaded,
        });
        print('---------------------------after----------------------------');
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        //...
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.code),
        ),
      );
      setState(() {
        _isAuthanticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                    left: 20, right: 20, bottom: 20, top: 30),
                width: 200,
                child: Image.asset('assets/images/chat.png'),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!_isLogin) ...[
                              UserImagePicker(
                                onPickedImage: (pickedImage) {
                                  _SelectedImage = pickedImage;
                                  print(_SelectedImage);
                                },
                              ),
                              TextFormField(
                                controller: _userName,
                                decoration: const InputDecoration(
                                    labelText: "User Name"),
                                autocorrect: false,
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().length < 4) {
                                    return 'Please enter atleast 4 character.';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            TextFormField(
                              controller: _emailaddress,
                              decoration: const InputDecoration(
                                  labelText: "Email Address"),
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.none,
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty ||
                                    !value.contains('@')) {
                                  return 'Please enter valid Email Address';
                                }
                                return null;
                              },
                            ),
                            TextFormField(
                              controller: _password,
                              decoration:
                                  const InputDecoration(labelText: "Password"),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.trim().length < 6) {
                                  return 'Password must be atleast 6 characters long.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            if (_isAuthanticating)
                              const CircularProgressIndicator(),
                            if (!_isAuthanticating)
                              ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer),
                                child: Text(_isLogin ? "Login" : "Signup"),
                              ),
                            if (!_isAuthanticating)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isLogin = !_isLogin;
                                  });
                                },
                                child: Text(_isLogin
                                    ? 'Create an account'
                                    : 'I already have an account.'),
                              ),
                          ],
                        )),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
