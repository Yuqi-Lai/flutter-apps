// This file contains sample questions that you can use to populate your Firestore database
// Run this once to add sample questions to your Firestore

import 'package:cloud_firestore/cloud_firestore.dart';

class SampleQuestions {
  static Future<void> addSampleQuestions() async {
    final firestore = FirebaseFirestore.instance;

    final questions = [
      {
        'question': 'What is Flutter built with?',
        'type': 'multipleChoiceSingle',
        'options': ['Java', 'Kotlin', 'Dart', 'Swift'],
        'correctAnswers': ['Dart'],
      },
      {
        'question': 'Dart is a statically typed programming language.',
        'type': 'trueFalse',
        'options': ['True', 'False'],
        'correctAnswers': ['True'],
      },
      {
        'question': 'Which of these are smartphone operating systems?',
        'type': 'multipleChoiceMultiple',
        'options': ['iOS', 'Android', 'Windows 11', 'HarmonyOS', 'Linux'],
        'correctAnswers': ['iOS', 'Android', 'HarmonyOS'],
      },
      {
        'question': 'What keyword is used to create a variable in Dart?',
        'type': 'multipleChoiceSingle',
        'options': ['let', 'var', 'const', 'define'],
        'correctAnswers': ['var'],
      },
      {
        'question': 'Smartphones can run Flutter applications.',
        'type': 'trueFalse',
        'options': ['True', 'False'],
        'correctAnswers': ['True'],
      },
      {
        'question': 'Which companies developed these smartphone OS?',
        'type': 'multipleChoiceMultiple',
        'options': ['Apple - iOS', 'Google - Android', 'Microsoft - iOS', 'Samsung - Tizen', 'Huawei - HarmonyOS'],
        'correctAnswers': ['Apple - iOS', 'Google - Android', 'Samsung - Tizen', 'Huawei - HarmonyOS'],
      },
      {
        'question': 'What is the main UI framework for building mobile apps with Dart?',
        'type': 'multipleChoiceSingle',
        'options': ['React Native', 'Flutter', 'Xamarin', 'Ionic'],
        'correctAnswers': ['Flutter'],
      },
      {
        'question': 'Dart supports async/await for asynchronous programming.',
        'type': 'trueFalse',
        'options': ['True', 'False'],
        'correctAnswers': ['True'],
      },
      {
        'question': 'Which are common smartphone sensors?',
        'type': 'multipleChoiceMultiple',
        'options': ['Accelerometer', 'Gyroscope', 'Barometer', 'Thermometer', 'GPS'],
        'correctAnswers': ['Accelerometer', 'Gyroscope', 'GPS'],
      },
      {
        'question': 'Which company created the Dart programming language?',
        'type': 'multipleChoiceSingle',
        'options': ['Apple', 'Google', 'Microsoft', 'Facebook'],
        'correctAnswers': ['Google'],
      },
      {
        'question': 'What does UI stand for in mobile development?',
        'type': 'multipleChoiceSingle',
        'options': ['User Interface', 'Universal Internet', 'Unified Integration', 'Update Information'],
        'correctAnswers': ['User Interface'],
      },
      {
        'question': 'Dart is an object-oriented programming language.',
        'type': 'trueFalse',
        'options': ['True', 'False'],
        'correctAnswers': ['True'],
      },
      {
        'question': 'Which are valid widget types in Flutter?',
        'type': 'multipleChoiceMultiple',
        'options': ['StatelessWidget', 'StatefulWidget', 'DynamicWidget', 'InheritedWidget', 'ReactiveWidget'],
        'correctAnswers': ['StatelessWidget', 'StatefulWidget', 'InheritedWidget'],
      },
      {
        'question': 'What is the default IDE recommended for Flutter development?',
        'type': 'multipleChoiceSingle',
        'options': ['Visual Studio', 'Android Studio', 'Eclipse', 'NetBeans'],
        'correctAnswers': ['Android Studio'],
      },
      {
        'question': 'iOS apps are primarily developed using Swift or Objective-C.',
        'type': 'trueFalse',
        'options': ['True', 'False'],
        'correctAnswers': ['True'],
      },
      {
        'question': 'Which are popular smartphone manufacturers?',
        'type': 'multipleChoiceMultiple',
        'options': ['Apple', 'Samsung', 'Dell', 'Xiaomi', 'HP'],
        'correctAnswers': ['Apple', 'Samsung', 'Xiaomi'],
      },
      {
        'question': 'What symbol is used for string interpolation in Dart?',
        'type': 'multipleChoiceSingle',
        'options': ['#', '@', '\$', '%'],
        'correctAnswers': ['\$'],
      },
      {
        'question': 'NFC technology is commonly found in modern smartphones.',
        'type': 'trueFalse',
        'options': ['True', 'False'],
        'correctAnswers': ['True'],
      },
      {
        'question': 'Which are Flutter layout widgets?',
        'type': 'multipleChoiceMultiple',
        'options': ['Column', 'Row', 'Loop', 'Container', 'Array'],
        'correctAnswers': ['Column', 'Row', 'Container'],
      },
      {
        'question': 'What is the primary programming language for Android development?',
        'type': 'multipleChoiceSingle',
        'options': ['Swift', 'Kotlin', 'C#', 'Ruby'],
        'correctAnswers': ['Kotlin'],
      },
      {
        'question': 'Dart supports null safety.',
        'type': 'trueFalse',
        'options': ['True', 'False'],
        'correctAnswers': ['True'],
      },
      {
        'question': 'Which are mobile app distribution platforms?',
        'type': 'multipleChoiceMultiple',
        'options': ['Google Play Store', 'Apple App Store', 'Steam', 'Huawei AppGallery', 'Netflix'],
        'correctAnswers': ['Google Play Store', 'Apple App Store', 'Huawei AppGallery'],
      },
      {
        'question': 'What does APK stand for in Android?',
        'type': 'multipleChoiceSingle',
        'options': ['Android Package Kit', 'Application Program Key', 'Android Program Kernel', 'App Package Key'],
        'correctAnswers': ['Android Package Kit'],
      },
      {
        'question': 'Flutter uses the Skia graphics engine.',
        'type': 'trueFalse',
        'options': ['True', 'False'],
        'correctAnswers': ['True'],
      },
      {
        'question': 'Which are valid Dart data types?',
        'type': 'multipleChoiceMultiple',
        'options': ['int', 'String', 'bool', 'float', 'double'],
        'correctAnswers': ['int', 'String', 'bool', 'double'],
      },
    ];
    
    // Add questions to Firestore
    for (var question in questions) {
      await firestore.collection('questions').add(question);
    }
    
    print('Sample questions added successfully!');
  }
}

