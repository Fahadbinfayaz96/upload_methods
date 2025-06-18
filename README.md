# 📤 Flutter File Upload Demo

This Flutter project demonstrates **three different file upload techniques** for large files (like videos), including:

1. **Multipart Upload**
2. **Chunked Upload (Streaming)**
3. **Direct PUT Upload to Pre-signed URL**

---

## 🚀 Features

- Switch between multipart and chunked uploads dynamically
- Progress bar during upload
- Time taken to upload (in ms)
- Toast notification on upload success
- Video preview after upload
- Tab-based navigation between upload methods

---

## 📁 Folder Structure

lib/ 
├── main.dart # App entry with TabBar navigation 
├── multipart_upload.dart # Combined Multipart & Chunked Upload UI 
└── direct_upload.dart # Pre-signed URL Direct PUT UI

---

## 📦 Dependencies

Make sure you have these in your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  image_picker: ^1.1.2
  dio: ^5.8.0+1
  rxdart: ^0.28.0
  video_player: ^2.9.5



