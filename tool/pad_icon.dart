// Applies -10% padding on all 4 sides to logo2.png:
// scales the image up by 20% (1 / (1 - 2*0.1) = 1.25 → but for -10% inset
// the content fills 120% of canvas, so scale = 1.20, then center-crop).
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final src = File('logo2.png').readAsBytesSync();
  final original = img.decodePng(src)!;

  final w = original.width;
  final h = original.height;

  // -10% padding each side → content = 120% of canvas in each dim
  // Scale up by 1.20, then crop center back to original size
  final scaledW = (w * 1.20).round();
  final scaledH = (h * 1.20).round();

  final scaled = img.copyResize(original, width: scaledW, height: scaledH,
      interpolation: img.Interpolation.cubic);

  final cropX = (scaledW - w) ~/ 2;
  final cropY = (scaledH - h) ~/ 2;

  final cropped = img.copyCrop(scaled, x: cropX, y: cropY, width: w, height: h);

  File('logo2_icon.png').writeAsBytesSync(img.encodePng(cropped));
  print('Written logo2_icon.png (${w}x${h})');
}
