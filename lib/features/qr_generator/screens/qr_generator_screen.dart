import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:warmindo_pos/core/theme/app_theme.dart';
import 'package:warmindo_pos/core/constants/app_constants.dart';
import 'package:warmindo_pos/features/catalog/models/table_model.dart';

class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TableModel> _tables = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchTables();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchTables() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('tables')
          .select()
          .order('table_number', ascending: true);

      setState(() {
        _tables = (response as List)
            .map((json) => TableModel.fromJson(json))
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data meja: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _generateNewTable() async {
    final tableNumberController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Meja Baru'),
        content: TextField(
          controller: tableNumberController,
          decoration: const InputDecoration(
            labelText: 'Nomor Meja',
            hintText: 'Contoh: 1, 2, A1, dll.',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = tableNumberController.text.trim();
              if (value.isNotEmpty) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    // Check if table number already exists
    final exists = _tables.any(
      (t) => t.tableNumber.toLowerCase() == result.toLowerCase(),
    );
    if (exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nomor meja sudah ada!'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
      return;
    }

    try {
      final qrCodeData = '${AppConstants.qrPrefix}$result';
      final response = await Supabase.instance.client.from('tables').insert({
        'table_number': result,
        'qr_code_data': qrCodeData,
        'status': 'available',
      }).select().single();

      final newTable = TableModel.fromJson(response);
      setState(() {
        _tables.add(newTable);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Meja $result berhasil ditambahkan!'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan meja: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  void _showQrBottomSheet(TableModel table) {
    final qrKey = GlobalKey();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'QR Code Meja ${table.tableNumber}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            RepaintBoundary(
              key: qrKey,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: table.qrCodeData,
                      version: QrVersions.auto,
                      size: 250,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppTheme.secondaryDark,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppTheme.secondaryDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Meja ${table.tableNumber}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppConstants.appName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareQr(table),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Bagikan'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadQr(qrKey, table),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Unduh'),
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

  Future<void> _shareQr(TableModel table) async {
    try {
      await Share.share(
        '${AppConstants.appName} - Meja ${table.tableNumber}\nScan QR code ini untuk memesan.\nData: ${table.qrCodeData}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membagikan: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _downloadQr(GlobalKey qrKey, TableModel table) async {
    try {
      final boundary =
          qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();

      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/qr_meja_${table.tableNumber}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR Code disimpan di: $filePath'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );

        // Also offer to share the saved file
        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'QR Code Meja ${table.tableNumber} - ${AppConstants.appName}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan QR: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _deleteTable(TableModel table) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Meja'),
        content: Text(
          'Apakah Anda yakin ingin menghapus Meja ${table.tableNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Supabase.instance.client
          .from('tables')
          .delete()
          .eq('id', table.id);

      setState(() {
        _tables.removeWhere((t) => t.id == table.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Meja ${table.tableNumber} berhasil dihapus'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus meja: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Generator'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.table_restaurant), text: 'QR Meja'),
            Tab(icon: Icon(Icons.qr_code), text: 'QR Pembayaran'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTableQrTab(),
          _buildPaymentQrTab(),
        ],
      ),
    );
  }

  Widget _buildTableQrTab() {
    return RefreshIndicator(
      onRefresh: _fetchTables,
      color: AppTheme.primaryOrange,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generateNewTable,
                icon: const Icon(Icons.add),
                label: const Text('Generate QR Meja Baru'),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryOrange,
                    ),
                  )
                : _tables.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 100),
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.table_restaurant_outlined,
                                  size: 80,
                                  color: AppTheme.textLight,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Belum ada meja',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Tap tombol di atas untuk menambahkan meja baru',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _tables.length,
                        itemBuilder: (context, index) {
                          final table = _tables[index];
                          return _buildTableCard(table);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCard(TableModel table) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.table_restaurant,
            color: AppTheme.primaryOrange,
          ),
        ),
        title: Text(
          'Meja ${table.tableNumber}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: table.isAvailable
                    ? AppTheme.accentGreen.withValues(alpha: 0.1)
                    : AppTheme.warningYellow.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                table.isAvailable ? 'Tersedia' : 'Terisi',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: table.isAvailable
                      ? AppTheme.accentGreen
                      : AppTheme.warningYellow,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _showQrBottomSheet(table),
              icon: const Icon(
                Icons.qr_code,
                color: AppTheme.primaryOrange,
              ),
              tooltip: 'Lihat QR',
            ),
            IconButton(
              onPressed: () => _deleteTable(table),
              icon: const Icon(
                Icons.delete_outline,
                color: AppTheme.accentRed,
              ),
              tooltip: 'Hapus',
            ),
          ],
        ),
        onTap: () => _showQrBottomSheet(table),
      ),
    );
  }

  Widget _buildPaymentQrTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.qr_code_2,
                size: 50,
                color: AppTheme.primaryOrange,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'QR Pembayaran QRIS',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'QR Pembayaran akan di-generate otomatis saat proses checkout dengan metode QRIS.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryOrange,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pilih metode pembayaran QRIS pada halaman checkout untuk menghasilkan QR pembayaran.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
