// lib/screens/edit_profile_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram_clone_flutter/models/user.dart' as model;
import 'package:instagram_clone_flutter/providers/user_provider.dart';
import 'package:instagram_clone_flutter/resources/auth_methods.dart';
import 'package:instagram_clone_flutter/utils/colors.dart';
import 'package:instagram_clone_flutter/utils/utils.dart';
import 'package:instagram_clone_flutter/widgets/text_field_input.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  final model.User user;
  const EditProfileScreen({super.key, required this.user});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  Uint8List? _image;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _bioController = TextEditingController(text: widget.user.bio);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // Method to select a new image
  void selectImage() async {
    Uint8List im = await pickImage(ImageSource.gallery);
    setState(() {
      _image = im;
    });
    }

  // Method to update the profile data
  void updateProfileData() async {
    setState(() {
      _isLoading = true;
    });

    String res = await AuthMethods().updateUserData(
      uid: widget.user.uid,
      username: _usernameController.text,
      bio: _bioController.text,
      file: _image, // Pass the new image if one was selected
    );

    setState(() {
      _isLoading = false;
    });

    if (res == 'success') {
      showSnackBar(context, 'Profile Updated!');
      // Refresh the user provider to get the new data
      await Provider.of<UserProvider>(context, listen: false).refreshUser();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      if (mounted) {
        showSnackBar(context, res);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Edit Profile'),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                      child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))),
                )
              : IconButton(
                  icon: const Icon(Icons.check, color: blueColor),
                  onPressed: updateProfileData,
                ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              
              // Profile Picture
              GestureDetector(
                onTap: selectImage,
                child: CircleAvatar(
                  radius: 64,
                  backgroundImage: _image != null
                      ? MemoryImage(_image!)
                      : NetworkImage(widget.user.photoUrl) as ImageProvider,
                ),
              ),
              TextButton(
                onPressed: selectImage,
                child: const Text(
                  'Change Profile Photo',
                  style: TextStyle(color: blueColor, fontSize: 16),
                ),
              ),
              const SizedBox(height: 24),

              // Username
              TextFieldInput(
                hintText: 'Username',
                textInputType: TextInputType.text,
                textEditingController: _usernameController,
              ),
              const SizedBox(height: 24),

              // Bio
              TextFieldInput(
                hintText: 'Bio',
                textInputType: TextInputType.multiline,
                textEditingController: _bioController,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}