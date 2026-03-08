import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageUtils {
  ImageUtils._();

  static Future<File?> compressImage(File file) async {
    final filePath = file.absolute.path;
    final outPath = '${filePath}_compressed.jpg';

    final XFile? result = await FlutterImageCompress.compressAndGetFile(
      filePath,
      outPath,
      quality: 70,
      minWidth: 800,
      minHeight: 800,
      format: CompressFormat.jpeg,
    );

    if (result == null) return null;
    return File(result.path);
  }

  static Future<Uint8List?> compressImageToBytes(File file) async {
    final result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      quality: 70,
      minWidth: 800,
      minHeight: 800,
      format: CompressFormat.jpeg,
    );
    return result;
  }
}
