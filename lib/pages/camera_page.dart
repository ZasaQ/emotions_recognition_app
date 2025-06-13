import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'package:emotions_recognition_app/utilities.dart';


class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  CameraLensDirection _currentLensDirection = CameraLensDirection.back;
  bool _isCameraReady = false;

  @override
  void initState() {
    super.initState();
    _initCameras();
  }

  Future<void> _initCameras() async {
    _cameras = await availableCameras();
    _setCamera(_currentLensDirection);
  }

  Future<void> _setCamera(CameraLensDirection direction) async {
    final selectedCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection == direction,
      orElse: () => _cameras.first,
    );

    _controller?.dispose();
    _controller = CameraController(selectedCamera, ResolutionPreset.medium);

    _isCameraReady = false;
    await _controller!.initialize();
    setState(() {
      _isCameraReady = true;
    });
  }

  Future<void> _switchCamera() async {
    if (_controller != null && _controller!.value.isInitialized) {
      await _controller!.dispose();
    }

    setState(() {
      _isCameraReady = false;
      _controller = null;
    });

    _currentLensDirection = (_currentLensDirection == CameraLensDirection.back)
        ? CameraLensDirection.front
        : CameraLensDirection.back;

    final newCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection == _currentLensDirection,
      orElse: () => _cameras.first,
    );

    _controller = CameraController(newCamera, ResolutionPreset.medium);

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isCameraReady = true;
        });
      }
    } catch (e) {
      appLog("Camera switch error: $e");
    }
  }

  Future<void> _takePicture() async {
    if (!_controller!.value.isInitialized) return;

    try {
      final image = await _controller!.takePicture();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Picture saved at ${image.path}")),
      );
    } catch (e) {
      appLog("Error taking picture: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Widget _buildRoundButton({required IconData icon, required VoidCallback onPressed}) {
    return RawMaterialButton(
      onPressed: onPressed,
      shape: const CircleBorder(),
      fillColor: Colors.white,
      padding: const EdgeInsets.all(16.0),
      elevation: 4.0,
      child: Icon(icon, size: 28.0, color: Colors.black),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (!_isCameraReady || _controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Camera Page")),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!), // full screen camera

          // Bottom action buttons
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Positioned(
                  bottom: 16.0,
                  left: MediaQuery.of(context).size.width / 2 - 28.0,
                  child: _buildRoundButton(
                    icon: Icons.camera_alt,
                    onPressed: _takePicture,
                  ),
                ),

                Positioned(
                  bottom: 16.0,
                  right: 16.0,
                  child: _buildRoundButton(
                    icon: Icons.flip_camera_android,
                    onPressed: _switchCamera,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}