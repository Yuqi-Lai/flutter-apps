import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class NewPostScreen extends StatefulWidget {
  const NewPostScreen({super.key});

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _conditionController = TextEditingController();
  final _contactInfoController = TextEditingController();
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  Position? _currentPosition;
  String? _locationName;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _conditionController.dispose();
    _contactInfoController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            _locationName = '${place.locality}, ${place.administrativeArea}';
          }
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (_selectedImages.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 4 images allowed')),
      );
      return;
    }

    try {
      // Use pickMultiImage to allow multiple image selection
      // Note: pickMultiImage opens the gallery by default on most devices
      // If it opens file picker, user can manually navigate to Photos/Gallery
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1024,
      );

      if (images.isNotEmpty && mounted) {
        setState(() {
          int remainingSlots = 4 - _selectedImages.length;
          _selectedImages.addAll(images.take(remainingSlots));
          
          if (images.length > remainingSlots) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Only ${remainingSlots} more image(s) allowed. Selected ${remainingSlots} image(s).')),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting images: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<List<String>> _uploadImages() async {
    final storage = FirebaseStorage.instance;
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final List<String> downloadUrls = [];

    Future<String> getDownloadUrlWithRetry(Reference ref) async {
      const maxAttempts = 3;
      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        try {
          return await ref.getDownloadURL();
        } on FirebaseException catch (e) {
          if (e.code == 'object-not-found' && attempt < maxAttempts - 1) {
            await Future.delayed(const Duration(milliseconds: 400));
            continue;
          }
          rethrow;
        }
      }
      throw FirebaseException(
        plugin: 'firebase_storage',
        code: 'object-not-found',
        message: 'File still missing after retries',
      );
    }

    for (int i = 0; i < _selectedImages.length; i++) {
      final image = _selectedImages[i];

      try {
        debugPrint('Uploading image $i (${image.path})');
        final bytes = await image.readAsBytes();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${timestamp}_${i}_$userId.jpg';

        final ref = storage.ref('posts/$userId/$fileName');
        debugPrint('Uploading image $i to ${ref.fullPath}');

        final uploadTask = ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        final snapshot = await uploadTask;

        if (snapshot.state == TaskState.success) {
          final url = await getDownloadUrlWithRetry(snapshot.ref);
          downloadUrls.add(url);
        } else {
          debugPrint('Upload failed for $fileName, state: ${snapshot.state}');
          throw FirebaseException(
            plugin: 'firebase_storage',
            code: 'upload-failed',
            message: 'Upload failed with state ${snapshot.state}',
          );
        }
      } catch (e, st) {
        debugPrint('Error uploading image $i: $e');
        debugPrint('$st');
        rethrow;
      }
    }

    return downloadUrls;
  }

  Future<void> _submitPost() async {
    debugPrint('Submit button tapped');
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      debugPrint('Submit aborted: form validation failed');
      return;
    }
    if (_selectedImages.isEmpty) {
      debugPrint('Submit aborted: no images selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('Form validated, starting upload...');
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final imageUrls = await _uploadImages();

      GeoPoint? geoPoint;
      if (_currentPosition != null) {
        geoPoint = GeoPoint(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
      }

      await FirebaseFirestore.instance.collection('posts').add({
        'title': _titleController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'description': _descriptionController.text.trim(),
        'condition': _conditionController.text.trim(),
        'contactInfo': _contactInfoController.text.trim(),
        'imageUrls': imageUrls,
        'userId': userId,
        'location': geoPoint,
        'locationName': _locationName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        debugPrint('Post saved, navigating back');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e, st) {
      debugPrint('Submit failed: $e');
      debugPrint('$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'New Post',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title *',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price *',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _conditionController,
                decoration: InputDecoration(
                  labelText: 'Condition (e.g., New, Like New, Used)',
                  prefixIcon: const Icon(Icons.info_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Description *',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactInfoController,
                decoration: InputDecoration(
                  labelText: 'Contact Info',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_locationName != null)
                Card(
                  child: ListTile(
                    leading: Icon(Icons.location_on, color: Colors.blue.shade700),
                    title: const Text('Location'),
                    subtitle: Text(_locationName!),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Images (${_selectedImages.length}/4) *',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (_selectedImages.isNotEmpty)
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(File(_selectedImages[index].path)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 12,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickImageFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Select Images from Device'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF007AFF), Color(0xFF0051D5)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF007AFF).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Post Item',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
