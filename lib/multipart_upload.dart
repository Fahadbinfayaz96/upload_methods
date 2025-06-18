import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});
  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  double progress = 0.0;
  bool isUploading = false;
  bool useChunkedUpload = false;
  String? uploadedVideoPath;
  int? uploadDurationMs;

  VideoPlayerController? _videoController;

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> pickAndUpload() async {
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

        if (response.statusCode == 200) {
          _showToast("✅ Chunked Upload Successful");
          uploadedVideoPath = filePath;
        } else {
          _showToast("Chunked Upload Failed");
        }
      } else {
        final url = "http://000.000.0.00:3000/upload-multipart";
        final formData = FormData.fromMap({
          "file": await MultipartFile.fromFile(filePath, filename: filename),
        });

        final response = await dio.put(
          url,
          data: formData,
          onSendProgress: (sent, total) {
            setState(() => progress = sent / total);
          },
        );

        if (response.statusCode == 200) {
          _showToast("✅ Multipart Upload Successful");
          uploadedVideoPath = filePath;
        } else {
          _showToast("Multipart Upload Failed");
        }
      }

      if (uploadedVideoPath != null) {
        _videoController?.dispose();
        _videoController = VideoPlayerController.file(File(uploadedVideoPath!));
        await _videoController!.initialize();
        setState(() {});
      }
    } catch (e) {
      _showToast(" Upload error: $e");
      log("Upload error: $e");
    } finally {
      stopwatch.stop();
      setState(() {
        isUploading = false;
        uploadDurationMs = stopwatch.elapsedMilliseconds;
      });
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
              SwitchListTile(
                title: Text(useChunkedUpload
                    ? "Chunked Upload Enabled"
                    : "Multipart Upload Enabled"),
                value: useChunkedUpload,
                onChanged: (val) => setState(() => useChunkedUpload = val),
              ),
              ElevatedButton(
                onPressed: isUploading ? null : pickAndUpload,
                child: const Text("Pick & Upload Video"),
              ),
              const SizedBox(height: 20),
              if (isUploading)
                Column(
                  children: [
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 8),
                    Text("Progress: $progressPercent%"),
                  ],
                ),
              if (uploadedVideoPath != null &&
                  _videoController != null &&
                  _videoController!.value.isInitialized)
                Column(
                  children: [
                    const SizedBox(height: 20),
                    AspectRatio(
                      aspectRatio: 7/7,
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
              if (uploadDurationMs != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text("Upload Time: $uploadDurationMs ms"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
