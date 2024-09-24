import 'package:flutter/material.dart';
import '../services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  String? _photoURL;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _bioController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final userData = await _userService.getUserData();
      setState(() {
        _displayNameController.text = userData['displayName'] ?? '';
        _bioController.text = userData['bio'] ?? '';
        _photoURL = userData['photoURL'];
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load user data. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(labelText: 'Display Name'),
                      validator: (value) => value!.isEmpty ? 'Please enter a display name' : null,
                    ),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(labelText: 'Bio'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveChanges,
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _userService.updateUserProfile(
          _displayNameController.text, 
          _bioController.text,
          _photoURL
        );
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      } catch (e) {
        print('Error updating profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile. Please try again.')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}