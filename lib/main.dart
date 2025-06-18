import 'package:flutter/material.dart';
import 'package:upload_test/direct_upload.dart';
import 'package:upload_test/multipart_upload.dart';

/// Main entry point for the Video Upload Demo application
/// 
/// This application demonstrates three different file upload methods:
/// 1. Multipart form upload
/// 2. Chunked streaming upload
/// 3. Direct upload with presigned URLs
/// 
/// The app features a tabbed interface to switch between different upload methods.
void main() {
  runApp(const MyApp());
}

/// Root widget of the application
/// 
/// Configures the global MaterialApp settings including:
/// - Application title
/// - Theme configuration
/// - Debug banner visibility
/// - Initial route
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const UploadHome(),
    );
  }
}

/// Home screen that provides navigation between different upload methods
/// 
/// Features:
/// - Tab-based navigation
/// - Two main upload method categories:
///   1. Multipart/Chunked uploads
///   2. Direct S3 uploads with presigned URLs
/// 
/// Uses a DefaultTabController to manage tab state and switching.
class UploadHome extends StatelessWidget {
  const UploadHome({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Video Upload Options"),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.upload_file),
                text: "Multipart / Chunked",
              ),
              Tab(
                icon: Icon(Icons.cloud_upload),
                text: "Direct",
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // First tab: Multipart and Chunked upload implementations
            UploadScreen(),
            
            // Second tab: Direct S3 upload implementation
            DirectUploadScreen(),
          ],
        ),
      ),
    );
  }
}