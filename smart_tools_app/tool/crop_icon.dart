import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/images/launcher_icon.png');
  final bytes = file.readAsBytesSync();
  final original = img.decodeImage(bytes)!;
  
  final w = original.width;
  final h = original.height;
  
  // Crop to remove white padding - take center 88% (gentle crop)
  final cropSize = (w * 0.88).round();
  final offsetX = ((w - cropSize) / 2).round();
  final offsetY = ((h - cropSize) / 2 - (h * 0.03)).round(); // shift content down
  
  final cropped = img.copyCrop(original, x: offsetX, y: offsetY, width: cropSize, height: cropSize);
  
  // Resize to 1024x1024 for best quality
  final resized = img.copyResize(cropped, width: 1024, height: 1024);
  
  // Save as adaptive foreground
  final output = File('assets/images/launcher_foreground.png');
  output.writeAsBytesSync(img.encodePng(resized));
  
  print('✓ Created launcher_foreground.png (${resized.width}x${resized.height})');
}
