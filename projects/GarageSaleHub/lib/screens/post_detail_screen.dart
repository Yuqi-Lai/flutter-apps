import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/post_model.dart';
import 'full_screen_image.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  int _currentImageIndex = 0;
  late PageController _pageController;
  late Future<DocumentSnapshot> _postFuture;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    debugPrint('PostDetailScreen: Initializing with postId: ${widget.postId}');
    _postFuture = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .get();
  }

  @override
  void didUpdateWidget(covariant PostDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.postId != widget.postId) {
      _currentImageIndex = 0;
      _postFuture = FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .get();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _deletePost(Post post) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != post.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only delete your own posts')),
      );
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading indicator
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Step 1: Delete images from Firebase Storage
      final storage = FirebaseStorage.instance;
      for (final imageUrl in post.imageUrls) {
        try {
          // Extract the path from the URL
          final ref = storage.refFromURL(imageUrl);
          await ref.delete();
          debugPrint('Deleted image from Storage: $imageUrl');
        } catch (e) {
          debugPrint('Error deleting image from Storage: $e');
          // Continue even if one image fails to delete
        }
      }

      // Step 2: Delete document from Firestore
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .delete();

      debugPrint('Post deleted successfully');

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.pop(context); // Close post detail screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting post: $e');
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Builder(
            builder: (context) {
              return FutureBuilder<DocumentSnapshot>(
                future: _postFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }
                  
                  final post = Post.fromFirestore(snapshot.data!);
                  final currentUser = FirebaseAuth.instance.currentUser;
                  final isOwner = currentUser != null && currentUser.uid == post.userId;

                  if (!isOwner) {
                    return const SizedBox.shrink();
                  }

                  return PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz, color: Colors.black),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deletePost(post);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete Post', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _postFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Post not found'),
            );
          }

          final post = Post.fromFirestore(snapshot.data!);
          
   
          debugPrint('Post location: ${post.location}');
          debugPrint('Post locationName: ${post.locationName}');
          
          return Builder(
            builder: (context) {
              final bottomInset = MediaQuery.of(context).padding.bottom;
              final buttonHeight = 60.0; 
              
              return CustomScrollView(
                physics: const ClampingScrollPhysics(),
                slivers: [
                  // Image carousel
                  SliverToBoxAdapter(
                    child: post.imageUrls.isNotEmpty
                        ? Builder(
                            builder: (context) {
                              // Log PageView initialization
                              debugPrint('PageView: Initializing with ${post.imageUrls.length} images');
                              debugPrint('PageView: Current index: $_currentImageIndex');
                              debugPrint('PageView: Controller has clients: ${_pageController.hasClients}');
                              
                              return SizedBox(
                                height: 260,
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    PageView.builder(
                                      controller: _pageController,
                                      allowImplicitScrolling: true,
                                      scrollDirection: Axis.horizontal,
                                      physics: const PageScrollPhysics(),
                                      itemCount: post.imageUrls.length,
                                      onPageChanged: (index) {
                                        debugPrint('PageView: ====== PAGE CHANGED ======');
                                        debugPrint('PageView: Changed to index $index');
                                        debugPrint('PageView: Previous index: $_currentImageIndex');
                                        debugPrint('PageView: Total images: ${post.imageUrls.length}');
                                        debugPrint('PageView: Image URL: ${post.imageUrls[index]}');
                                        setState(() {
                                          _currentImageIndex = index;
                                        });
                                        debugPrint('PageView: State updated, new index: $_currentImageIndex');
                                      },
                                      itemBuilder: (context, index) {
                                        debugPrint('PageView: Building item at index $index of ${post.imageUrls.length}');
                                        debugPrint('PageView: Image URL[$index]: ${post.imageUrls[index]}');
                                        return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => FullScreenImage(
                                                  imageUrls: post.imageUrls,
                                                  initialIndex: index,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Image.network(
                                            post.imageUrls[index],
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Container(
                                                color: Colors.grey.shade200,
                                                child: Center(
                                                  child: CircularProgressIndicator(
                                                    value: loadingProgress.expectedTotalBytes != null
                                                        ? loadingProgress.cumulativeBytesLoaded /
                                                            loadingProgress.expectedTotalBytes!
                                                        : null,
                                                    strokeWidth: 2,
                                                  ),
                                                ),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              debugPrint('Image load error: $error');
                                              debugPrint('Image URL: ${post.imageUrls[index]}');
                                              return Container(
                                                color: Colors.grey.shade300,
                                                child: Icon(
                                                  Icons.image_not_supported,
                                                  size: 80,
                                                  color: Colors.grey.shade600,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                if (post.imageUrls.length > 1)
                                  Positioned(
                                    bottom: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: List.generate(
                                          post.imageUrls.length,
                                          (index) => AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            margin: const EdgeInsets.symmetric(horizontal: 4),
                                            width: _currentImageIndex == index ? 10 : 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                _currentImageIndex == index ? 0.9 : 0.5,
                                              ),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                            },
                          )
                        : AspectRatio(
                            aspectRatio: 1.0,
                            child: Container(
                              color: Colors.grey.shade300,
                              child: Center(
                                child: Icon(
                                  Icons.image,
                                  size: 80,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                  ),

              // Title, Price, Time and Location
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${post.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Listed ${_getTimeAgo(post.createdAt)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (post.locationName != null) ...[
                            Text(
                              ' in ${post.locationName}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Action buttons: Message, Save, Share
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildIOSActionButton(
                          icon: Icons.message_outlined,
                          label: 'Message',
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildIOSActionButton(
                          icon: Icons.bookmark_border,
                          label: 'Save',
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildIOSActionButton(
                          icon: Icons.share_outlined,
                          label: 'Share',
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.more_horiz),
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: Divider(height: 32)),

              // About this item section
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'About this item',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (post.condition.isNotEmpty)
                        _buildInfoRow(
                          icon: Icons.check_circle_outline,
                          label: 'Condition',
                          value: post.condition,
                        ),
                      if (post.contactInfo.isNotEmpty)
                        _buildInfoRow(
                          icon: Icons.phone,
                          label: 'Contact',
                          value: post.contactInfo,
                        ),
                      _buildInfoRow(
                        icon: Icons.calendar_today,
                        label: 'Listed',
                        value: DateFormat('MMM dd, yyyy').format(post.createdAt),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: Divider(height: 24)),

              // Seller's description
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Seller's description",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        post.description,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Map section
              if (post.location != null)
                SliverPadding(
                  padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(
                                  post.location!.latitude,
                                  post.location!.longitude,
                                ),
                                zoom: 14,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId('post_location'),
                                  position: LatLng(
                                    post.location!.latitude,
                                    post.location!.longitude,
                                  ),
                                  infoWindow: InfoWindow(title: post.title),
                                ),
                              },
                              zoomControlsEnabled: false,
                              myLocationButtonEnabled: false,
                              mapToolbarEnabled: false,
                              scrollGesturesEnabled: false,
                              tiltGesturesEnabled: false,
                              rotateGesturesEnabled: false,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (post.locationName != null)
                          Text(
                            post.locationName!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        Text(
                          'Location is approximate',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                  // Dynamic bottom padding for button
                  SliverPadding(
                    padding: EdgeInsets.only(
                      bottom: buttonHeight + bottomInset + 4,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: Builder(
        builder: (context) {
          final bottomInset = MediaQuery.of(context).padding.bottom;
          return Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: bottomInset + 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Container(
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
                onPressed: () {
                  // Message action
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Message',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 24,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: Colors.black87),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
