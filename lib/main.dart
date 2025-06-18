import 'package:flutter/material.dart';
import 'package:upload_test/direct_upload.dart';
import 'package:upload_test/multipart_upload.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        
      ),
      debugShowCheckedModeBanner: false,
      home:  UploadHome(),
    );
  }
}


class UploadHome extends StatelessWidget {
  const UploadHome({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Two tabs: Multipart/Chunked and Direct
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Video Upload Options"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Multipart / Chunked"),
              Tab(text: "Direct"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            UploadScreen(),        
            DirectUploadScreen(), 
          ],
        ),
      ),
    );
  }
}
