import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

Future<void> seedSamplePosts() async {
  try {
    final postsRef = FirebaseFirestore.instance.collection('posts');

    // Check if sample posts already exist (posts with userId = 'sample')
    // Add timeout to prevent hanging
    final existing = await postsRef.where('userId', isEqualTo: 'sample').limit(1).get().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        // Return empty result if timeout
        return postsRef.where('userId', isEqualTo: 'sample').limit(0).get();
      },
    );
    if (existing.docs.isNotEmpty) {
      debugPrint('Sample posts already exist, skipping seeding.');
      debugPrint('To update sample posts, delete them from Firebase Console first, or use forceUpdateSamplePosts().');
      return;
    }
    debugPrint('No existing sample posts found, starting to seed sample posts...');

    final now = DateTime.now();
    // Default location: San Jose, CA
    final defaultLocation = GeoPoint(37.3382, -121.8863);
    const defaultLocationName = 'San Jose, CA';
    
    final samplePosts = [
      {
        'title': 'Instant Camera',
        'price': 35.00,
        'description': 'Compact instant camera, great for parties and trips.',
        'condition': 'Good',
        'imageUrls': [
          'https://images.unsplash.com/photo-1683821291961-e79e6d10a2cc?q=80&w=774&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
          'https://images.unsplash.com/photo-1613600143671-234a54c236eb?q=80&w=1778&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
        ],
      },
      {
        'title': 'Cat Tree',
        'price': 15.00,
        'description': 'Sturdy cat tree with multiple platforms and scratch posts.',
        'condition': 'Used',
        'imageUrls': [
          'https://images.unsplash.com/photo-1601758065893-25c11bfa69b5?q=80&w=878&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D'
        ],
      },
      {
        'title': 'Tennis Racket',
        'price': 20.00,
        'description': 'Lightweight tennis racket in good condition.',
        'condition': 'Good',
        'imageUrls': [
          'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?q=80&w=870&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D'
        ],
      },
    ];

    for (final post in samplePosts) {
      await postsRef.add({
        'title': post['title'],
        'price': post['price'],
        'description': post['description'],
        'condition': post['condition'] ?? '',
        'contactInfo': '',
        'imageUrls': post['imageUrls'],
        'userId': 'sample',
        'location': defaultLocation,
        'locationName': defaultLocationName,
        'createdAt': now,
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Failed to add post: timeout');
        },
      );
      debugPrint('Added sample post: ${post['title']}');
    }
    debugPrint('Sample posts seeded successfully.');
  } catch (e) {
    debugPrint('Error seeding sample posts: $e');
  }
}

Future<void> forceUpdateSamplePosts() async {
  try {
    final postsRef = FirebaseFirestore.instance.collection('posts');
    
    // Try to delete all sample posts (posts with userId = 'sample')
    // If deletion fails due to permissions, we'll still create new posts
    try {
      debugPrint('Attempting to delete old sample posts...');
      final samplePostsQuery = await postsRef.where('userId', isEqualTo: 'sample').get();
      int deletedCount = 0;
      for (final doc in samplePostsQuery.docs) {
        try {
          await doc.reference.delete();
          deletedCount++;
        } catch (e) {
          debugPrint('Failed to delete post ${doc.id}: $e');
        }
      }
      debugPrint('Deleted $deletedCount old sample posts.');
      // Wait a bit to ensure deletion is complete
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('Could not delete old sample posts (permission issue): $e');
      debugPrint('Continuing to create new sample posts anyway...');
    }
    
    // Now create new posts directly (skip the check in seedSamplePosts)
    debugPrint('Creating new sample posts...');
    final now = DateTime.now();
    // Default location: San Jose, CA
    final defaultLocation = GeoPoint(37.3382, -121.8863);
    const defaultLocationName = 'San Jose, CA';
    
    final samplePosts = [
      {
        'title': 'Instant Camera',
        'price': 50.00,
        'description': 'Compact instant camera, great for parties and trips.',
        'condition': 'Good',
        'imageUrls': [
          'https://images.unsplash.com/photo-1683821291961-e79e6d10a2cc?q=80&w=774&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
          'https://images.unsplash.com/photo-1613600143671-234a54c236eb?q=80&w=1778&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
        ],
      },
      {
        'title': 'Cat Tree',
        'price': 15.00,
        'description': 'Sturdy cat tree with multiple platforms and scratch posts.',
        'condition': 'Used',
        'imageUrls': [
          'https://images.unsplash.com/photo-1601758065893-25c11bfa69b5?q=80&w=878&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D'
        ],
      },
      {
        'title': 'Tennis Racket',
        'price': 20.00,
        'description': 'Lightweight tennis racket in good condition.',
        'condition': 'Good',
        'imageUrls': [
          'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?q=80&w=870&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D'
        ],
      },
    ];

    for (final post in samplePosts) {
      await postsRef.add({
        'title': post['title'],
        'price': post['price'],
        'description': post['description'],
        'condition': post['condition'] ?? '',
        'contactInfo': '',
        'imageUrls': post['imageUrls'],
        'userId': 'sample',
        'location': defaultLocation,
        'locationName': defaultLocationName,
        'createdAt': now,
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Failed to add post: timeout');
        },
      );
      debugPrint('Added sample post: ${post['title']}');
    }
    debugPrint('Sample posts force updated successfully.');
  } catch (e) {
    debugPrint('Error force updating sample posts: $e');
  }
}

