import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:warmindo_pos/core/constants/app_constants.dart';
import 'package:warmindo_pos/core/theme/app_theme.dart';
import 'package:warmindo_pos/features/cart/providers/cart_provider.dart';
import 'package:warmindo_pos/features/catalog/models/table_model.dart';

class QrScannerScreen extends StatefulWidget {
  final VoidCallback? onTableBound;

  const QrScannerScreen({
    super.key,
    this.onTableBound,
  });

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
    if (rawValue == null || rawValue.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
      _hasScanned = true;
    });

    await _processQrData(rawValue.trim());
  }

  Future<void> _processQrData(String rawData) async {
    try {
      // Ekstraksi nomor meja secara cerdas
      String tableNumber = rawData;
      String qrCodeData = rawData;

      if (rawData.startsWith(AppConstants.qrPrefix)) {
        tableNumber = rawData.replaceFirst(AppConstants.qrPrefix, '').trim();
      } else {
        // Jika scan QR dengan format bebas atau input manual
        tableNumber = rawData.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').trim();
        qrCodeData = '${AppConstants.qrPrefix}$tableNumber';
      }

      if (tableNumber.isEmpty) {
        _showError('Nomor meja tidak valid.');
        return;
      }

      TableModel? targetTable;

      // Coba cari atau daftarkan meja di Supabase dengan timeout 3 detik
      try {
        final existing = await Supabase.instance.client
            .from('tables')
            .select()
            .or('qr_code_data.eq.$qrCodeData,table_number.eq.$tableNumber')
            .maybeSingle()
            .timeout(const Duration(seconds: 3));

        if (existing != null) {
          targetTable = TableModel.fromJson(existing);
          // Update status meja menjadi occupied
          try {
            await Supabase.instance.client
                .from('tables')
                .update({'status': 'occupied'})
                .eq('id', targetTable.id)
                .timeout(const Duration(seconds: 2));
          } catch (_) {}
        } else {
          // Meja belum ada di DB, buatkan secara otomatis
          try {
            final insertRes = await Supabase.instance.client
                .from('tables')
                .insert({
                  'table_number': tableNumber,
                  'qr_code_data': qrCodeData,
                  'status': 'occupied',
                })
                .select()
                .single()
                .timeout(const Duration(seconds: 3));

            targetTable = TableModel.fromJson(insertRes);
          } catch (_) {
            // Jika insert gagal karena RLS, buat objek meja lokal
            targetTable = TableModel(
              id: DateTime.now().millisecondsSinceEpoch % 100000,
              tableNumber: tableNumber,
              qrCodeData: qrCodeData,
              status: 'occupied',
              createdAt: DateTime.now(),
            );
          }
        }
      } catch (e) {
        debugPrint('Supabase table lookup error/timeout: $e');
        // Fallback: tetap ikat nomor meja ke sesi keranjang agar kasir tidak terhenti
        targetTable = TableModel(
          id: DateTime.now().millisecondsSinceEpoch % 100000,
          tableNumber: tableNumber,
          qrCodeData: qrCodeData,
          status: 'occupied',
          createdAt: DateTime.now(),
        );
      }

      if (!mounted) return;

      // 1. Simpan meja ke CartProvider
      final cartProvider = context.read<CartProvider>();
      cartProvider.setTable(targetTable.copyWith(status: 'occupied'));

      // 2. Reset status scanner agar siap jika nanti kembali ke layar ini
      setState(() {
        _isProcessing = false;
        _hasScanned = false;
      });

      // 3. Tampilkan notifikasi sukses
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Meja $tableNumber berhasil terhubung! Silakan pilih menu.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.accentGreen,
          duration: const Duration(seconds: 3),
        ),
      );

      // 4. Arahkan kasir langsung ke Katalog Menu!
      if (widget.onTableBound != null) {
        widget.onTableBound!();
      } else if (context.canPop()) {
        context.pop();
      } else {
        context.go('/dashboard');
      }
    } catch (e) {
      _showError('Gagal memproses QR Meja: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _hasScanned = false;
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.accentRed,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showManualInputDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit_note, color: AppTheme.warmindoRed),
            SizedBox(width: 8),
            Text('Input Nomor Meja'),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nomor Meja',
            hintText: 'Contoh: 01, 02, 03',
            prefixIcon: Icon(Icons.table_restaurant),
          ),
          autofocus: true,
          keyboardType: TextInputType.text,
          onSubmitted: (value) {
            final val = value.trim();
            if (val.isNotEmpty) {
              Navigator.pop(dialogContext);
              setState(() {
                _isProcessing = true;
                _hasScanned = true;
              });
              _processQrData(val);
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
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                Navigator.pop(dialogContext);
                setState(() {
                  _isProcessing = true;
                  _hasScanned = true;
                });
                _processQrData(val);
              }
            },
            child: const Text('Hubungkan Meja'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final scanArea = screenSize.width * 0.72;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera viewfinder
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),

          // Viewfinder Overlay
          _buildScanOverlay(screenSize, scanArea),

          // Top bar
          _buildTopBar(),

          // Bottom area (Manual Input & Info)
          _buildBottomArea(),

          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.65),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: AppTheme.warmindoYellow,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 18),
                    Text(
                      'Menghubungkan ke Meja...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
        borderColor: AppTheme.warmindoYellow,
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner, color: AppTheme.warmindoYellow, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Pindai QR Meja',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
                color: _isTorchOn ? AppTheme.warmindoYellow : Colors.white,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomArea() {
    return Positioned(
      bottom: 24,
      left: 20,
      right: 20,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Arahkan kamera ke QR Code di meja pelanggan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _showManualInputDialog,
                icon: const Icon(Icons.keyboard, color: Colors.white),
                label: const Text(
                  'Input Manual Nomor Meja',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warmindoRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
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
    final backgroundPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);

    final left = (size.width - scanAreaSize) / 2;
    final top = (size.height - scanAreaSize) / 2.3;
    final right = left + scanAreaSize;
    final bottom = top + scanAreaSize;
    final scanRect = Rect.fromLTRB(left, top, right, bottom);

    // Draw dark background outside cutout
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, backgroundPaint);

    // Draw corner markers
    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    const cornerLength = 26.0;

    // Top-left
    canvas.drawLine(Offset(left, top + cornerLength), Offset(left, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), cornerPaint);

    // Top-right
    canvas.drawLine(Offset(right - cornerLength, top), Offset(right, top), cornerPaint);
    canvas.drawLine(Offset(right, top), Offset(right, top + cornerLength), cornerPaint);

    // Bottom-left
    canvas.drawLine(Offset(left, bottom - cornerLength), Offset(left, bottom), cornerPaint);
    canvas.drawLine(Offset(left, bottom), Offset(left + cornerLength, bottom), cornerPaint);

    // Bottom-right
    canvas.drawLine(Offset(right - cornerLength, bottom), Offset(right, bottom), cornerPaint);
    canvas.drawLine(Offset(right, bottom), Offset(right, bottom - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
