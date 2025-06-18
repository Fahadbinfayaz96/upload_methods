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

lib
---> main.dart # App entry with TabBar navigation 
---> multipart_upload.dart # Combined Multipart & Chunked Upload UI 
---> direct_upload.dart # Pre-signed URL Direct PUT UI

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


Demo Videos:

- [Direct Upload](https://jam.dev/c/72b067db-19c8-4ca4-8b3a-767607b455f6)

- [Multipart and Chunked](https://jam.dev/c/ce165fd1-ea8f-41bb-b8f2-d1b2b08e6b2d)

[click here](www.google.com)


