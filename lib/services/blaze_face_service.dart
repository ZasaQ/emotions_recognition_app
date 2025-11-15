import 'dart:math';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'package:emotions_recognition_app/utilities.dart';


class BoundingBox {
  final double xmin, ymin, xmax, ymax, score;

  BoundingBox({
    required this.xmin,
    required this.ymin,
    required this.xmax,
    required this.ymax,
    required this.score,
  });
}

class BlazeFaceService {
  late Interpreter _interpreter;
  late List<List<List<double>>> _regressors;
  late List<List<List<double>>> _classificators;

  double _highestScore = 0;
  double _lowestScore = 1.0;
  double _lastHighestScore = 0.0;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset(
      'assets/models/blazeface.tflite',
      options: InterpreterOptions()..threads = 4,
    );
    
    _regressors = List.generate(
        1, (_) => List.generate(896, (_) => List.filled(16, 0.0)));
    _classificators = List.generate(
        1, (_) => List.generate(896, (_) => List.filled(1, 0.0)));
    
    appLog('BlazeFace model loaded and buffers initialized.');
  }

  /// Sigmoid helper function
  double sigmoid(double x) => 1 / (1 + exp(-x));

  double iou(BoundingBox a, BoundingBox b) {
    final double x1 = max(a.xmin, b.xmin);
    final double y1 = max(a.ymin, b.ymin);
    final double x2 = min(a.xmax, b.xmax);
    final double y2 = min(a.ymax, b.ymax);

    final double interArea = max(0, x2 - x1) * max(0, y2 - y1);
    final double boxAArea = (a.xmax - a.xmin) * (a.ymax - a.ymin);
    final double boxBArea = (b.xmax - b.xmin) * (b.ymax - b.ymin);

    return interArea / (boxAArea + boxBArea - interArea);
  }

  List<BoundingBox> nonMaximumSuppression(
    List<BoundingBox> boxes, {
    double iouThreshold = 0.3,
  }) {
    final List<BoundingBox> picked = [];
    boxes.sort((a, b) => b.score.compareTo(a.score));

    final used = List<bool>.filled(boxes.length, false);

    for (int i = 0; i < boxes.length; i++) {
      if (used[i]) continue;
      picked.add(boxes[i]);
      for (int j = i + 1; j < boxes.length; j++) {
        if (!used[j] && iou(boxes[i], boxes[j]) > iouThreshold) {
          used[j] = true;
        }
      }
    }
    return picked;
  }

  Future<List<Map<String, dynamic>>> detectFacesFromCapture(
    CameraController controller, {
    double threshold = 0.75,
  }) async {
    try {
      final xFile = await controller.takePicture();
      final imageBytes = await xFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        appLog("Failed to decode captured image");
        return [];
      }
      
      return detectFaces(image, threshold: threshold);
    } catch (e) {
      appLog("Error capturing and detecting: $e");
      return [];
    }
  }

  List<Map<String, dynamic>> detectFaces(
    img.Image? image, {
    double threshold = 0.75,
  }) {
    if (image == null) {
      appLog("No image to validate");
      return [];
    }

    appLog("Image input size: ${image.width}x${image.height}");

    final resized = img.copyResizeCropSquare(image, size: 128);
    appLog("Resized to 128x128 (crop square)");

    final input = [
      List.generate(128, (y) => List.generate(128, (x) {
            final pixel = resized.getPixel(x, y);
            return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
          })),
    ];

    _regressors = List.generate(
        1, (_) => List.generate(896, (_) => List.filled(16, 0.0)));
    _classificators = List.generate(
        1, (_) => List.generate(896, (_) => List.filled(1, 0.0)));
    final outputs = {0: _regressors, 1: _classificators};

    try {
      final start = DateTime.now();
      _interpreter.runForMultipleInputs([input], outputs);
      appLog(
          "Inference done in ${DateTime.now().difference(start).inMilliseconds}ms");
    } catch (e) {
      appLog("Error running interpreter: $e");
      return [];
    }

    final regressionOutput = outputs[0] as List;
    final classifierOutput = outputs[1] as List;

    if (classifierOutput.isEmpty ||
        classifierOutput[0].isEmpty ||
        classifierOutput[0][0].isEmpty) {
      appLog("Classifier output seems empty or malformed");
      return [];
    }

    List<BoundingBox> rawBoxes = [];
    List<double> allScores = [];

    for (int i = 0; i < 896; i++) {
      final confidence = sigmoid(classifierOutput[0][i][0]);
      allScores.add(confidence);

      if (confidence >= threshold) {
        final bbox = regressionOutput[0][i];
        rawBoxes.add(BoundingBox(
          xmin: bbox[1],
          ymin: bbox[0],
          xmax: bbox[3],
          ymax: bbox[2],
          score: confidence,
        ));
      }
    }

    if (allScores.isEmpty) {
      appLog("No scores were produced by the model.");
      return [];
    }

    // Score statistics
    allScores.sort((a, b) => b.compareTo(a));
    final topScores =
        allScores.take(10).map((s) => s.toStringAsFixed(3)).toList();
    
    if (allScores.first > _highestScore) {
      _highestScore = allScores.first;
    }
    if (allScores.isNotEmpty && allScores.last < _lowestScore) {
      _lowestScore = allScores.last;
    }
    
    _lastHighestScore = allScores.isNotEmpty ? allScores.first : 0.0;

    appLog("================================================");
    appLog("Top 10 confidence scores: $topScores");
    appLog("All-time Min: ${_lowestScore.toStringAsFixed(3)}, Max: ${_highestScore.toStringAsFixed(3)}");
    appLog("Detections above threshold ($threshold): ${rawBoxes.length}");

    final finalBoxes = nonMaximumSuppression(rawBoxes);
    appLog("Final boxes after NMS: ${finalBoxes.length}");

    if (finalBoxes.isEmpty) {
      appLog("No faces detected.");
      return [];
    }
    appLog("================================================");

    return finalBoxes.map((b) => {'confidence': b.score, 'bbox': b}).toList();
  }

  double getHighestScore() {
    return _lastHighestScore;
  }

  void close() {
    _interpreter.close();
    appLog('BlazeFace model closed.');
  }
}