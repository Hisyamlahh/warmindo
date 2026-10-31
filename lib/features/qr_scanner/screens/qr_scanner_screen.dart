import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:warmindo_pos/core/theme/app_theme.dart';
import 'package:warmindo_pos/core/constants/app_constants.dart';
import 'package:warmindo_pos/features/cart/providers/cart_provider.dart';
import 'package:warmindo_pos/features/catalog/models/table_model.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  bool _isProcessing = false;
  bool _hasScanned = false;
  bool _isTorchOn = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _hasScanned) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final rawValue = barcode.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _hasScanned = true;
    });

    await _processQrData(rawValue);
  }

  Future<void> _processQrData(String qrData) async {
    try {
      if (!qrData.startsWith(AppConstants.qrPrefix)) {
        _showError('QR Code tidak valid. Bukan QR meja Warmindo.');
        return;
      }

      final tableNumber = qrData.replaceFirst(AppConstants.qrPrefix, '');

      if (tableNumber.isEmpty) {
        _showError('QR Code tidak valid. Nomor meja tidak ditemukan.');
        return;
      }

      // Query table from Supabase
      final response = await Supabase.instance.client
          .from('tables')
          .select()
          .eq('qr_code_data', qrData)
          .maybeSingle();

      if (response == null) {
        _showError('Meja tidak ditemukan di sistem.');
        return;
      }

      final table = TableModel.fromJson(response);

      // Update table status to occupied
      await Supabase.instance.client
          .from('tables')
          .update({'status': 'occupied'}).eq('id', table.id);

      if (!mounted) return;

      // Set table in cart provider
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.setTable(table.copyWith(status: 'occupied'));

      // Show success and navigate
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Meja ${table.tableNumber} dipilih!'),
          backgroundColor: AppTheme.accentGreen,
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate to catalog/dashboard
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      _showError('Terjadi kesalahan: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _hasScanned = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.accentRed,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showManualInputDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Input Manual'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nomor Meja',
            hintText: 'Masukkan nomor meja',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(dialogContext);
              _processQrData('${AppConstants.qrPrefix}${value.trim()}');
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.pop(dialogContext);
                _processQrData('${AppConstants.qrPrefix}$value');
              }
            },
            child: const Text('Cari Meja'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final scanArea = screenSize.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera viewfinder
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),

          // Overlay
          _buildScanOverlay(screenSize, scanArea),

          // Top bar
          _buildTopBar(),

          // Bottom area
          _buildBottomArea(),

          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: AppTheme.primaryOrange,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Memproses QR Code...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay(Size screenSize, double scanArea) {
    return CustomPaint(
      size: screenSize,
      painter: _ScanOverlayPainter(
        scanAreaSize: scanArea,
        borderColor: AppTheme.primaryOrange,
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black38,
              ),
            ),
            const Expanded(
              child: Text(
                'Scan QR Meja',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              onPressed: () async {
                try {
                  await _scannerController.toggleTorch();
                  setState(() {
                    _isTorchOn = !_isTorchOn;
                  });
                } catch (_) {}
              },
              icon: Icon(
                _isTorchOn ? Icons.flash_on : Icons.flash_off,
                color: _isTorchOn ? AppTheme.warningYellow : Colors.white,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomArea() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Arahkan kamera ke QR Code meja',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _showManualInputDialog,
                icon: const Icon(
                  Icons.keyboard,
                  color: AppTheme.primaryOrange,
                ),
                label: const Text(
                  'Input Manual',
                  style: TextStyle(
                    color: AppTheme.primaryOrange,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  final double scanAreaSize;
  final Color borderColor;

  _ScanOverlayPainter({
    required this.scanAreaSize,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scanRect = Rect.fromCenter(
      center: center,
      width: scanAreaSize,
      height: scanAreaSize,
    );

    // Draw semi-transparent overlay
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );

    // Draw corner decorations
    final cornerLength = scanAreaSize * 0.12;
    const cornerWidth = 4.0;
    final cornerPaint = Paint()
      ..color = borderColor
      ..strokeWidth = cornerWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final left = scanRect.left;
    final top = scanRect.top;
    final right = scanRect.right;
    final bottom = scanRect.bottom;
    const radius = 16.0;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cornerLength)
        ..lineTo(left, top + radius)
        ..arcToPoint(
          Offset(left + radius, top),
          radius: const Radius.circular(radius),
        )
        ..lineTo(left + cornerLength, top),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(right - cornerLength, top)
        ..lineTo(right - radius, top)
        ..arcToPoint(
          Offset(right, top + radius),
          radius: const Radius.circular(radius),
        )
        ..lineTo(right, top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(left, bottom - cornerLength)
        ..lineTo(left, bottom - radius)
        ..arcToPoint(
          Offset(left + radius, bottom),
          radius: const Radius.circular(radius),
        )
        ..lineTo(left + cornerLength, bottom),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(right - cornerLength, bottom)
        ..lineTo(right - radius, bottom)
        ..arcToPoint(
          Offset(right, bottom - radius),
          radius: const Radius.circular(radius),
        )
        ..lineTo(right, bottom - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
