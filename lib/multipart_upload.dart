import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

/// A Flutter widget for handling video uploads with two different methods:
/// 1. Multipart form upload (default)
/// 2. Chunked streaming upload
///
/// Features:
/// - Toggle between upload methods
/// - Real-time progress tracking
/// - Video preview after upload
/// - Upload performance metrics
class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  /// Current upload progress (0.0 to 1.0)
  double progress = 0.0;

  /// Flag indicating if an upload is in progress
  bool isUploading = false;

  /// Toggle between chunked and multipart upload
  bool useChunkedUpload = false;

  /// Path to the uploaded video file
  String? uploadedVideoPath;

  /// Time taken for upload in milliseconds
  int? uploadDurationMs;

  /// Controller for video playback preview
  VideoPlayerController? _videoController;

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  /// Main upload handler that:
  /// 1. Selects video from gallery
  /// 2. Configures Dio client
  /// 3. Performs upload based on selected method
  /// 4. Handles response and initializes video player
  Future<void> pickAndUpload() async {
    // Step 1: Pick video from gallery
    final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (file == null) return;

    final filename = file.name;
    final filePath = file.path;
    final dio = Dio();

    setState(() {
      isUploading = true;
      progress = 0.0;
      uploadedVideoPath = null;
      uploadDurationMs = null;
    });

    final stopwatch = Stopwatch()..start();

    try {
      if (useChunkedUpload) {
        // Chunked upload implementation
        await _performChunkedUpload(dio, filename, filePath);
      } else {
        // Multipart upload implementation
        await _performMultipartUpload(dio, filename, filePath);
      }

      // Initialize video player if upload succeeded
      if (uploadedVideoPath != null) {
        await _initializeVideoPlayer();
      }
    } catch (e) {
      _showToast("Upload error: $e");
      log("Upload error: $e");
    } finally {
      stopwatch.stop();
      setState(() {
        isUploading = false;
        uploadDurationMs = stopwatch.elapsedMilliseconds;
      });
    }
  }

  /// Performs chunked streaming upload
  ///
  /// @param dio The Dio client instance
  /// @param filename Name of the file to upload
  /// @param filePath Local path to the video file
  Future<void> _performChunkedUpload(
      Dio dio, String filename, String filePath) async {
    final url = "http://000.000.0.00:3000/upload-chunked/$filename";
    final totalBytes = File(filePath).lengthSync();
    final fileStream = File(filePath).openRead();

    final response = await dio.put(
      url,
      data: fileStream,
      options: Options(headers: {
        HttpHeaders.contentTypeHeader: "video/mp4",
        HttpHeaders.contentLengthHeader: totalBytes,
      }),
      onSendProgress: (sent, total) {
        setState(() => progress = sent / total);
      },
    );
    log("response .......${response}");
    if (response.statusCode == 200) {
      _showToast("✅ Chunked Upload Successful");
      uploadedVideoPath = filePath;
    } else {
      _showToast("Chunked Upload Failed");
    }
  }

  /// Performs multipart form upload
  ///
  /// @param dio The Dio client instance
  /// @param filename Name of the file to upload
  /// @param filePath Local path to the video file
  Future<void> _performMultipartUpload(
      Dio dio, String filename, String filePath) async {
    final url = "http://000.000.0.00:3000/upload-multipart";
    final formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(filePath, filename: filename),
    });

    log("from data ${formData.fields}");
    final response = await dio.put(
      url,
      data: formData,
      onSendProgress: (sent, total) {
        setState(() => progress = sent / total);
      },
    );
    log("Multipart response status: ${response.statusCode}");
    log("Multipart response ${response.data}");
    if (response.statusCode == 200) {
      _showToast("✅ Multipart Upload Successful");
      uploadedVideoPath = filePath;
    } else {
      _showToast("Multipart Upload Failed");
    }
  }

  /// Initializes the video player controller with the uploaded file
  Future<void> _initializeVideoPlayer() async {
    _videoController?.dispose();
    _videoController = VideoPlayerController.file(File(uploadedVideoPath!));
    await _videoController!.initialize();
    setState(() {});
  }

  /// Displays a snackbar with the given message
  void _showToast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final progressPercent = (progress * 100).toStringAsFixed(1);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Upload method toggle
              SwitchListTile(
                  title: Text(useChunkedUpload
                      ? "Chunked Upload Enabled"
                      : "Multipart Upload Enabled"),
                  value: useChunkedUpload,
                  onChanged: (val) {
                    setState(() {
                      useChunkedUpload = val;
                      // Reset video when switching to chunked mode
                      if (val) {
                        _videoController?.pause();
                        _videoController?.dispose();
                        _videoController = null;
                        uploadedVideoPath = null;
                        progress = 0.0;
                      }
                    });
                  }),

              // Upload button
              ElevatedButton(
                onPressed: isUploading ? null : pickAndUpload,
                child: const Text("Pick & Upload Video"),
              ),

              const SizedBox(height: 20),

              // Progress indicator
              if (isUploading)
                Column(
                  children: [
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 8),
                    Text("Progress: $progressPercent%"),
                  ],
                ),

              // Video preview section
              if (uploadedVideoPath != null &&
                  _videoController != null &&
                  _videoController!.value.isInitialized)
                Column(
                  children: [
                    const SizedBox(height: 20),
                    AspectRatio(
                      aspectRatio: 7 / 7,
                      child: VideoPlayer(_videoController!),
                    ),
                    VideoProgressIndicator(_videoController!,
                        allowScrubbing: true),
                    IconButton(
                      icon: Icon(_videoController!.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow),
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
              if (uploadDurationMs != null && uploadedVideoPath != null) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text("Upload Time: $uploadDurationMs ms"),
                ),
                Builder(
                  builder: (_) {
                    final file = File(uploadedVideoPath!);
                    final fileSizeMB = file.lengthSync() / (1024 * 1024);
                    final speedMbps = (file.lengthSync() * 8) /
                        (uploadDurationMs! / 1000) /
                        1024 /
                        1024;
                    final memoryMB = ProcessInfo.currentRss / (1024 * 1024);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("File Size: ${fileSizeMB.toStringAsFixed(2)} MB"),
                        Text(
                            "Upload Speed: ${speedMbps.toStringAsFixed(2)} Mbps"),
                        Text(
                            "App Memory Usage: ${memoryMB.toStringAsFixed(2)} MB"),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
