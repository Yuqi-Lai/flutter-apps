import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path/path.dart' as path;
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'screens/login_screen.dart';
import 'screens/photo_history_screen.dart';

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling a background message: ${message.messageId}');
  print('Message data: ${message.data}');
  print('Message notification: ${message.notification?.title}');
}

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Set up FCM background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();
  
  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.first;
  
  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: AuthWrapper(camera: firstCamera),
    ),
  );
}

// Auth wrapper to handle authentication state
class AuthWrapper extends StatelessWidget {
  final CameraDescription camera;
  
  const AuthWrapper({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // If user is logged in, show camera screen
        if (snapshot.hasData) {
          return TakePictureScreen(camera: camera);
        }
        
        // If user is not logged in, show login screen
        return const LoginScreen();
      },
    );
  }
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({super.key, required this.camera});
  
  final CameraDescription camera;
  
  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableLandmarks: false,
      enableClassification: false,
      enableTracking: false,
      minFaceSize: 0.1,
    ),
  );
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );
    
    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
    
    // Initialize FCM
    _initializeFCM();
  }

  Future<void> _initializeFCM() async {
    // Request notification permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Get FCM token
    _messaging.getToken().then((token) {
      setState(() {
        _fcmToken = token;
      });
      print('FCM Token: $token');
    });

    // Handle token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      setState(() {
        _fcmToken = newToken;
      });
      print('FCM Token refreshed: $newToken');
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${message.notification?.title ?? "Notification"}: ${message.notification?.body ?? ""}',
              ),
              duration: const Duration(seconds: 4),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      print('Message data: ${message.data}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification opened: ${message.notification?.title ?? "Notification"}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      }
    });

    // Check if app was opened from a notification
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from notification: ${initialMessage.notification?.title}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('App opened from notification: ${initialMessage.notification?.title ?? "Notification"}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    _faceDetector.close();
    super.dispose();
  }

  Future<String?> _uploadToFirebaseStorage(String imagePath) async {
    try {
      final String fileName = path.basename(imagePath);
      final File imageFile = File(imagePath);
      
      final ref = _storage.ref(fileName);
      await ref.putFile(
        imageFile,
        SettableMetadata(
          customMetadata: <String, String>{
            'uploaded_by': 'Camera App',
            'description': 'Photo taken from camera',
          },
        ),
      );
      
      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.message}')),
        );
      }
      return null;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload error: $e')),
        );
      }
      return null;
    }
  }

  Future<bool> _detectFace(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final List<Face> faces = await _faceDetector.processImage(inputImage);
      return faces.isNotEmpty;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Face detection error: $e')),
        );
      }
      return false;
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed out successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Take a picture'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('FCM Token'),
                  content: SelectableText(
                    _fcmToken ?? 'Token not available yet',
                    style: const TextStyle(fontSize: 12),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                    if (_fcmToken != null)
                      TextButton(
                        onPressed: () {
                          // Copy token to clipboard would require clipboard package
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Use this token in Firebase Console to send notifications'),
                            ),
                          );
                          Navigator.of(context).pop();
                        },
                        child: const Text('OK'),
                      ),
                  ],
                ),
              );
            },
            tooltip: 'Show FCM Token',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('User Profile'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email: ${user?.email ?? "N/A"}'),
                        const SizedBox(height: 8),
                        Text('User ID: ${user?.uid ?? "N/A"}'),
                        const SizedBox(height: 8),
                        Text('Provider: ${user?.providerData.firstOrNull?.providerId ?? "N/A"}'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              } else if (value == 'history') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PhotoHistoryScreen(),
                  ),
                );
              } else if (value == 'logout') {
                _signOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'history',
                child: Row(
                  children: [
                    Icon(Icons.photo_library),
                    SizedBox(width: 8),
                    Text('Photo History'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        // Provide an onPressed callback.
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            // Ensure that the camera is initialized.
            await _initializeControllerFuture;
            
            // Attempt to take a picture and get the file `image`
            // where it was saved.
            final image = await _controller.takePicture();
            
            if (!context.mounted) return;
            
            // Show loading indicator
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Processing image...'),
                duration: Duration(seconds: 1),
              ),
            );
            
            // Upload to Firebase Storage
            final storageUrl = await _uploadToFirebaseStorage(image.path);
            
            // Detect face using ML Kit
            final hasFace = await _detectFace(image.path);
            
            if (!context.mounted) return;
            
            // Save photo record to Firestore
            if (storageUrl != null) {
              final user = _authService.currentUser;
              if (user != null) {
                try {
                  await _firestoreService.savePhotoRecord(
                    userId: user.uid,
                    userEmail: user.email ?? 'Unknown',
                    fileName: path.basename(image.path),
                    storageUrl: storageUrl,
                    hasFace: hasFace,
                  );
                  print('Photo record saved to Firestore');
                } catch (e) {
                  print('Failed to save to Firestore: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Firestore save failed: $e'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              }
            }
            
            if (!context.mounted) return;
            
            // Show result in Snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  hasFace
                      ? 'Face detected! ✓ Photo saved to Firestore'
                      : 'No face detected ✗ Photo saved to Firestore',
                ),
                duration: const Duration(seconds: 3),
                backgroundColor: hasFace ? Colors.green : Colors.orange,
              ),
            );
            
            // If the picture was taken, display it on a new screen.
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => DisplayPictureScreen(
                  // Pass the automatically generated path to
                  // the DisplayPictureScreen widget.
                  imagePath: image.path,
                ),
              ),
            );
          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  
  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Image.file(File(imagePath)),
    );
  }
}
