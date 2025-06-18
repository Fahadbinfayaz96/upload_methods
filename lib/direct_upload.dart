import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:rxdart/rxdart.dart';
import 'package:video_player/video_player.dart';

/// A Flutter widget for handling direct video uploads to S3 using presigned URLs
///
/// This screen allows users to:
/// 1. Pick a video from their gallery
/// 2. Generate a presigned URL from the backend
/// 3. Upload the video directly to S3 storage
/// 4. Preview the uploaded video with playback controls
class DirectUploadScreen extends StatefulWidget {
  const DirectUploadScreen({super.key});

  @override
  State<DirectUploadScreen> createState() => _DirectUploadScreenState();
}

class _DirectUploadScreenState extends State<DirectUploadScreen> {
  /// The selected video file for upload
  File? _file;

  /// Loading state indicator
  bool _isLoading = false;

  /// Stream controller for upload progress updates (0.0 to 1.0)
  final BehaviorSubject<double> _progressSubject = BehaviorSubject.seeded(0.0);

  /// Time taken for the upload operation
  Duration? _uploadDuration;

  /// URL of the successfully uploaded video
  String? _uploadedVideoUrl;

  /// Controller for video playback
  VideoPlayerController? _videoController;

  @override
  void dispose() {
    _progressSubject.close();
    _videoController?.dispose();
    super.dispose();
  }

  /// Main function that handles the complete upload flow:
  /// 1. Picks a video from gallery
  /// 2. Prepares upload metadata
  /// 3. Gets presigned URL
  /// 4. Performs the upload
  /// 5. Initializes video playback
  Future<void> pickAndUpload() async {
    try {
      // Step 1: Pick video from gallery
      final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (picked == null) return;

      setState(() {
        _isLoading = true;
        _uploadedVideoUrl = null;
        _videoController?.dispose();
        _videoController = null;
      });
      _progressSubject.add(0.0);
      _file = File(picked.path);

      // Step 2: Prepare upload metadata
      final extension = picked.path.split('.').last.toLowerCase();
      final fileName =
          "uploads/${DateTime.now().millisecondsSinceEpoch}.$extension";
      final contentType = _getContentType(extension);

      // Step 3: Get presigned URL from backend
      final presignedUrl =
          await getPresignedUrl(fileName, contentType: contentType);
      if (presignedUrl == null) throw 'Failed to get upload URL';

      // Step 4: Perform the upload
      await _simplePutUpload(presignedUrl, contentType);
      _progressSubject.add(1.0);

      // Step 5: Initialize video player for preview
      _uploadedVideoUrl = presignedUrl;
      _videoController = VideoPlayerController.network(_uploadedVideoUrl!)
        ..initialize().then((_) {
          setState(() {});
          _videoController!.pause();
        });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upload successful!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
      _progressSubject.addError(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Performs a simple PUT upload to the given presigned URL
  ///
  /// @param url The presigned URL for direct upload
  /// @param contentType The MIME type of the video file
  /// @throws Exception if upload fails (non-200 response)
  Future<void> _simplePutUpload(String url, String contentType) async {
    final stopwatch = Stopwatch()..start();
    final response = await http.put(
      Uri.parse(url),
      headers: {'Content-Type': contentType},
      body: await _file!.readAsBytes(),
    );

    stopwatch.stop();

    if (response.statusCode != 200) {
      throw 'Upload failed (${response.statusCode})';
    } else {
      _uploadDuration = stopwatch.elapsed;
      log('Direct upload completed in ${stopwatch.elapsed.inMilliseconds}ms');
    }
  }

  /// Requests a presigned URL from the backend server
  ///
  /// @param fileName The desired filename in S3
  /// @param contentType Optional MIME type for the file
  /// @return String? The presigned URL or null if request fails
  Future<String?> getPresignedUrl(String fileName,
      {String? contentType}) async {
    try {
      final uri = Uri.parse('http://localhost:3000/generate-presigned-url')
          .replace(queryParameters: {
        'key': fileName,
        if (contentType != null) 'contentType': contentType,
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      return response.statusCode == 200
          ? jsonDecode(response.body)['url']
          : null;
    } catch (e) {
      print("Presigned URL error: $e");
      return null;
    }
  }

  /// Determines the appropriate Content-Type header based on file extension
  ///
  /// @param extension The file extension (without dot)
  /// @return String The corresponding MIME type
  String _getContentType(String extension) {
    switch (extension) {
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      default:
        return 'video/mp4';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Upload progress indicator
            if (_isLoading) ...[
              const SizedBox(height: 20),
              StreamBuilder<double>(
                stream: _progressSubject.stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(
                      'Error: ${snapshot.error}',
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    );
                  }

                  final progress = snapshot.data ?? 0;
                  return Column(
                    children: [
                      if (progress < 1) ...[
                        LinearProgressIndicator(value: progress),
                        Text('${(progress * 100).toStringAsFixed(1)}%'),
                      ] else ...[
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 40),
                        const Text('Upload Complete!'),
                      ],
                    ],
                  );
                },
              ),
            ] else
              // Upload button
              ElevatedButton(
                onPressed: pickAndUpload,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text("Pick & Upload Video"),
              ),

            const SizedBox(height: 20),

            // Video preview section
            if (_uploadedVideoUrl != null &&
                _videoController != null &&
                _videoController!.value.isInitialized)
              Column(
                children: [
                  AspectRatio(
                    aspectRatio: 7 / 7,
                    child: VideoPlayer(_videoController!),
                  ),
                  VideoProgressIndicator(_videoController!,
                      allowScrubbing: true),
                  IconButton(
                    icon: Icon(
                      _videoController!.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    onPressed: () {
                      setState(() {
                        _videoController!.value.isPlaying
                            ? _videoController!.pause()
                            : _videoController!.play();
                      });
                    },
                  ),
                ],
              ),

            // Upload metrics
            if (_file != null && _uploadDuration != null) ...[
              Text("Upload Time: ${_uploadDuration!.inMilliseconds} ms"),
              Text(
                  "File Size: ${(_file!.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB"),
              if (_uploadDuration!.inMilliseconds > 0)
                Text(
                    "Speed: ${((_file!.lengthSync() * 8) / (_uploadDuration!.inMilliseconds / 1000) / 1024 / 1024).toStringAsFixed(2)} Mbps"),
              Text(
                "App Memory Usage: ${(ProcessInfo.currentRss / (1024 * 1024)).toStringAsFixed(2)} MB",
              ),
            ],

            const SizedBox(height: 20),

            // Helper text
            Text(
              'This uses direct PUT upload. Best for small/medium files.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
