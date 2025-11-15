import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'package:image/image.dart' as img;

import 'package:emotions_recognition_app/services/blaze_face_service.dart';
import 'package:emotions_recognition_app/utilities.dart';


class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late BlazeFaceService _blazeFaceService;
  CameraController? _controller;
  bool _isCameraReady = false;
  bool _isProcessing = false;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;

  List<Map<String, dynamic>> _detectedFaces = [];
  img.Image? _capturedImage;
  bool _hasResults = false;
  double _highestConfidence = 0.0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  bool _isDisposing = false;

  @override
  void deactivate() {
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        _controller!.pausePreview();
      } catch (e) {
        appLog('Error pausing in deactivate: $e');
      }
    }
    super.deactivate();
  }

  @override
  void dispose() {
    if (!_isDisposing) {
      _isDisposing = true;
      _disposeCamera();
      _blazeFaceService.close();
    }
    super.dispose();
  }

  Future<void> _disposeCamera() async {
    try {
      if (_controller != null && _controller!.value.isInitialized) {
        try {
          await _controller!.pausePreview();
        } catch (e) {
          appLog('Error pausing preview: $e');
        }
        
        await Future.delayed(const Duration(milliseconds: 200));
        
        if (_controller!.value.isStreamingImages) {
          try {
            await _controller!.stopImageStream();
          } catch (e) {
            appLog('Error stopping stream: $e');
          }
        }
        
        await Future.delayed(const Duration(milliseconds: 200));
        
        try {
          await _controller!.dispose();
        } catch (e) {
          appLog('Error disposing controller: $e');
        }
        
        _controller = null;
      }
    } catch (e) {
      appLog('Error in _disposeCamera: $e');
      _controller = null;
    }
  }

  Future<void> _init() async {
    // Load BlazeFace model
    _blazeFaceService = BlazeFaceService();
    await _blazeFaceService.loadModel();

    // Initialize cameras
    _cameras = await availableCameras();
    _currentCameraIndex = _cameras.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
    );
    if (_currentCameraIndex == -1) _currentCameraIndex = 0;

    await _startCamera(_cameras[_currentCameraIndex]);
  }

  Future<void> _startCamera(CameraDescription camera) async {
    try {
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _controller!.initialize();

      if (mounted) {
        setState(() => _isCameraReady = true);
      }
    } catch (e) {
      appLog('Error starting camera: $e');
      if (mounted) {
        setState(() => _isCameraReady = false);
      }
    }
  }

  bool _isSwitchingCamera = false;

  void _switchCamera() async {
    if (_cameras.length < 2 || _isProcessing || _isSwitchingCamera) return;

    setState(() {
      _isSwitchingCamera = true;
      _isCameraReady = false;
    });

    try {
      _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
      
      await _disposeCamera();
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (mounted) {
        await _startCamera(_cameras[_currentCameraIndex]);
      }
    } catch (e) {
      appLog('Error switching camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to switch camera')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSwitchingCamera = false);
      }
    }
  }

  Future<void> _captureAndDetect() async {
    if (_controller == null || 
        !_controller!.value.isInitialized || 
        _isProcessing ||
        !mounted) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final xFile = await _controller!.takePicture();
      
      if (!mounted) return;
      
      final imageBytes = await xFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        appLog('Failed to decode captured image');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to process image')),
          );
        }
        return;
      }

      final detected = _blazeFaceService.detectFaces(image, threshold: 0.75);
      
      _highestConfidence = _blazeFaceService.getHighestScore();

      if (!mounted) return;

      setState(() {
        _capturedImage = image;
        _detectedFaces = detected;
        _hasResults = true;
      });
    } catch (e) {
      appLog('Error capturing and detecting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _retakePhoto() {
    setState(() {
      _hasResults = false;
      _detectedFaces = [];
      _capturedImage = null;
      _highestConfidence = 0.0;
    });
  }

  Widget _buildCameraView() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Take Photo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),
          
          // Camera controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildRoundButton(),
                _buildCaptureButton(),
                const SizedBox(width: 48, height: 48),
              ],
            ),
          ),
          
          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Detecting faces...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    final faceCount = _detectedFaces.length;
    final confidences = _detectedFaces
        .map((f) => (f['confidence'] as double))
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 1,
        title: const Text('Detection Results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _retakePhoto,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Captured image
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  img.encodeJpg(_capturedImage!),
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Face count summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: faceCount > 0
                      ? [Colors.green[400]!, Colors.green[600]!]
                      : [Colors.grey[400]!, Colors.grey[600]!],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (faceCount > 0 ? Colors.green : Colors.grey)
                        .withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.face,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    faceCount == 1 ? '1 Face' : '$faceCount Faces',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Detected',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),

            if (faceCount > 0) ...[
              const SizedBox(height: 24),

              // Detailed results card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.analytics_outlined, 
                              color: Colors.deepPurple),
                          SizedBox(width: 8),
                          Text(
                            'Confidence Scores',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...confidences.asMap().entries.map((entry) {
                        final index = entry.key;
                        final conf = entry.value;
                        final confValue = conf;
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Face ${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${(confValue * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: confValue,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.green[600]!,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Info card
              Card(
                color: Colors.blue[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Higher confidence scores indicate more certain face detection.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (faceCount == 0) ...[
              const SizedBox(height: 24),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.analytics_outlined, color: Colors.deepPurple),
                          SizedBox(width: 8),
                          Text(
                            'Confidence Score',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${(_highestConfidence * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Highest model activation.',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: _highestConfidence,
                        minHeight: 10,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// Original "No faces detected" card
              Card(
                color: Colors.orange[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Try taking another photo with better lighting or positioning.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _retakePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Another'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(width: 2),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _isProcessing ? null : _captureAndDetect,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.3),
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: _isProcessing
            ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : const Icon(Icons.camera_alt, color: Colors.white, size: 36),
      ),
    );
  }

  Widget _buildRoundButton() {
    const double size = 48;
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      elevation: 4.0,
      child: InkWell(
        onTap: _isSwitchingCamera ? () {} : _switchCamera,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          child: const Icon(Icons.flip_camera_android, size: size * 0.5, color: Colors.black87),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraReady || _controller == null || _isSwitchingCamera) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('Camera'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              Text(
                _isSwitchingCamera ? 'Switching camera...' : 'Loading camera...',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return _hasResults ? _buildResultsView() : _buildCameraView();
  }
}