// import 'dart:io';

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
// import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:flutter/widgets.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:video_player/video_player.dart';

class NewMessages extends StatefulWidget {
  const NewMessages({super.key});

  @override
  State<NewMessages> createState() => _NewMessagesState();
}

class _NewMessagesState extends State<NewMessages> {
  // XFile? videoFile;
  final _newMessage = TextEditingController();
  // VideoPlayerController? _videoController;

  @override
  void dispose() {
    _newMessage.dispose();
    // _videoController?.dispose();
    super.dispose();
  }

  // void pickVideo() async {
  //   final picker = ImagePicker();

  //   try {
  //     videoFile = await picker.pickVideo(source: ImageSource.gallery);

  //     // upload video
  //     // Function to upload file to Firebase Storage
  //     final user = FirebaseAuth.instance.currentUser!;
  //     final ref =
  //         FirebaseStorage.instance.ref().child('videos/${user.uid}.mp4}');
  //     await ref.putFile(File(videoFile!.path));
  //     final videoUploaded = await ref.getDownloadURL();
  //     print('---------------------------before------------------------');
  //     await FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(user.uid)
  //         .update({
  //       'fileUrl': videoUploaded,
  //     });
  //     print('---------------------------after----------------------------');
  //   } on FirebaseAuthException catch (error) {
  //     print('Error uploading file: $error');
  //   }
  // }

  // void _initializeVideo() {
  //   _videoController = VideoPlayerController.file(File(videoFile!.path))
  //     ..initialize().then((value) {
  //       setState(() {
  //         _videoController!.play();
  //         Dialog(
  //           child: _videoPreview(),
  //         );
  //       });
  //     });
  // }

  // Widget _videoPreview() {
  //   if (_videoController != null) {
  //     return AspectRatio(
  //       aspectRatio: _videoController!.value.aspectRatio,
  //       child: VideoPlayer(_videoController!),
  //     );
  //   } else {
  //     return const CircularProgressIndicator();
  //   }
  // }

  void submitMessage() async {
    final enterMessage = _newMessage.text;

    if (enterMessage.trim().isEmpty) {
      return;
    }
    //clear the data
    _newMessage.clear();
    //closing keyboard
    FocusScope.of(context).unfocus();
    // send it to firebase
    final user = FirebaseAuth.instance.currentUser!;
    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    FirebaseFirestore.instance.collection('chat').add({
      'type': "text",
      'text': enterMessage,
      'createdAt': Timestamp.now(),
      'userId': user.uid,
      'username': userData.data()!['userName'],
      'userImage': userData.data()!['image_url'],
    });
  }

// Image picker
  File? _SelectedImage;
  void _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 150,
    );
    if (pickedImage == null) {
      return;
    }
    _SelectedImage = File(pickedImage.path);
    if (_SelectedImage == null) return;
    try {
      final Reference storeRef = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child('${UniqueKey()}.jpg');
      await storeRef.putFile(_SelectedImage!);
      final imageUploaded = await storeRef.getDownloadURL();
      print(imageUploaded);
      print('---------------------------before------------------------');
      final user2 = FirebaseAuth.instance.currentUser!;
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user2.uid)
          .get();
      FirebaseFirestore.instance.collection('chat').add({
        'type': "img",
        'text': imageUploaded,
        'createdAt': Timestamp.now(),
        'userId': user2.uid,
        'username': userData.data()!['userName'],
        'userImage': userData.data()!['image_url'],
      });
      print('---------------------------after----------------------------');
    } on FirebaseAuthException catch (error) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.code),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 1, bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _newMessage,
              autocorrect: true,
              enableSuggestions: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: "send a message...",
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.camera_alt,
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ), // Replace with your desired document icon
                  onPressed: _pickImage,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: submitMessage,
            icon: Icon(
              Icons.send,
              color: Theme.of(context).colorScheme.primary,
            ),
          )
        ],
      ),
    );
  }
}
