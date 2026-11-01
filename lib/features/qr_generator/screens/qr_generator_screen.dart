import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:warmindo_pos/core/constants/app_constants.dart';
import 'package:warmindo_pos/core/theme/app_theme.dart';
import 'package:warmindo_pos/features/auth/providers/auth_provider.dart';
import 'package:warmindo_pos/features/catalog/models/table_model.dart';

class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  List<TableModel> _tables = [];
  bool _isLoading = false;
  String _statusFilter = 'all'; // 'all', 'available', 'occupied'

  @override
  void initState() {
    super.initState();
    _fetchTables();
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

  Future<void> _updateTableStatus(TableModel table, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('tables')
          .update({'status': newStatus})
          .eq('id', table.id);

      setState(() {
        final idx = _tables.indexWhere((t) => t.id == table.id);
        if (idx != -1) {
          _tables[idx] = table.copyWith(status: newStatus);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'available'
                  ? 'Meja ${table.tableNumber} sekarang KOSONG / TERSEDIA.'
                  : 'Meja ${table.tableNumber} sekarang TERISI.',
            ),
            backgroundColor: newStatus == 'available'
                ? AppTheme.warmindoGreen
                : AppTheme.warmindoRed,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah status meja: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _generateNewTable() async {
    final tableNumberController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_circle_outline, color: AppTheme.warmindoRed),
            SizedBox(width: 8),
            Text('Tambah Meja Baru'),
          ],
        ),
        content: TextField(
          controller: tableNumberController,
          decoration: const InputDecoration(
            labelText: 'Nomor Meja',
            hintText: 'Contoh: 01, 02, A1',
            prefixIcon: Icon(Icons.table_restaurant),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warmindoRed,
            ),
            child: const Text('Generate QR'),
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
            content: Text('Meja $result berhasil ditambahkan & QR dibuat!'),
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
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_2, color: AppTheme.warmindoRed, size: 28),
                const SizedBox(width: 8),
                Text(
                  'QR Code Meja ${table.tableNumber}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: table.isAvailable
                    ? AppTheme.warmindoGreen.withValues(alpha: 0.12)
                    : AppTheme.warmindoRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                table.isAvailable ? 'Status: Tersedia (Kosong)' : 'Status: Terisi (Ada Pelanggan)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: table.isAvailable ? AppTheme.warmindoGreen : AppTheme.warmindoRed,
                ),
              ),
            ),
            const SizedBox(height: 20),
            RepaintBoundary(
              key: qrKey,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: table.qrCodeData,
                      version: QrVersions.auto,
                      size: 240,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppTheme.warmindoRed,
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
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Warmindo JugaJago',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.warmindoRed,
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
                    label: const Text('Unduh / Cetak'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warmindoGreen,
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
            content: Text('QR Code disimpan: $filePath'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );

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
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.userRole == 'admin';

    return _buildTableContent(isAdmin);
  }

  Widget _buildTableContent(bool isAdmin) {
    final totalCount = _tables.length;
    final availableCount = _tables.where((t) => t.isAvailable).length;
    final occupiedCount = _tables.where((t) => !t.isAvailable).length;

    final filteredTables = _tables.where((t) {
      if (_statusFilter == 'available') return t.isAvailable;
      if (_statusFilter == 'occupied') return !t.isAvailable;
      return true;
    }).toList();

    return RefreshIndicator(
      onRefresh: _fetchTables,
      color: AppTheme.warmindoRed,
      child: Column(
        children: [
          // 1. Statistics Cards
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Total Meja',
                    count: totalCount,
                    color: AppTheme.textPrimary,
                    icon: Icons.table_restaurant,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    title: 'Tersedia',
                    count: availableCount,
                    color: AppTheme.warmindoGreen,
                    icon: Icons.check_circle_outline,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    title: 'Terisi',
                    count: occupiedCount,
                    color: AppTheme.warmindoRed,
                    icon: Icons.people_alt_outlined,
                  ),
                ),
              ],
            ),
          ),

          // 2. Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _TableFilterChip(
                  label: 'Semua ($totalCount)',
                  isSelected: _statusFilter == 'all',
                  onSelected: () => setState(() => _statusFilter = 'all'),
                ),
                const SizedBox(width: 8),
                _TableFilterChip(
                  label: 'Tersedia ($availableCount)',
                  isSelected: _statusFilter == 'available',
                  color: AppTheme.warmindoGreen,
                  onSelected: () => setState(() => _statusFilter = 'available'),
                ),
                const SizedBox(width: 8),
                _TableFilterChip(
                  label: 'Terisi ($occupiedCount)',
                  isSelected: _statusFilter == 'occupied',
                  color: AppTheme.warmindoRed,
                  onSelected: () => setState(() => _statusFilter = 'occupied'),
                ),
              ],
            ),
          ),

          // 3. Admin Add Table Button OR Cashier Info Notice
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generateNewTable,
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                  label: const Text(
                    'Generate QR Meja Baru (Admin)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warmindoRed,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.warmindoYellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.warmindoYellow),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: AppTheme.textPrimary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mode Kasir: Anda dapat memantau dan mengubah status meja (Tersedia / Terisi). Penambahan meja baru hanya oleh Admin.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
            ),

          // 4. Tables List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.warmindoRed,
                    ),
                  )
                : filteredTables.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 60),
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.table_restaurant_outlined,
                                  size: 70,
                                  color: AppTheme.textLight,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Tidak ada meja dengan filter ini',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredTables.length,
                        itemBuilder: (context, index) {
                          final table = filteredTables[index];
                          return _buildTableCard(table, isAdmin);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCard(TableModel table, bool isAdmin) {
    final isAvailable = table.isAvailable;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isAvailable
              ? AppTheme.warmindoGreen.withValues(alpha: 0.4)
              : AppTheme.warmindoRed.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                // Table Icon & Badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? AppTheme.warmindoGreen.withValues(alpha: 0.12)
                        : AppTheme.warmindoRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.table_restaurant,
                    color: isAvailable ? AppTheme.warmindoGreen : AppTheme.warmindoRed,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meja ${table.tableNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isAvailable
                                  ? AppTheme.warmindoGreen.withValues(alpha: 0.15)
                                  : AppTheme.warmindoRed.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isAvailable ? Icons.check_circle : Icons.person,
                                  size: 13,
                                  color: isAvailable ? AppTheme.warmindoGreen : AppTheme.warmindoRed,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isAvailable ? 'TERSEDIA' : 'TERISI',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isAvailable ? AppTheme.warmindoGreen : AppTheme.warmindoRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // View QR code button
                IconButton(
                  onPressed: () => _showQrBottomSheet(table),
                  icon: const Icon(Icons.qr_code, color: AppTheme.warmindoRed, size: 26),
                  tooltip: 'Lihat QR',
                ),

                // Delete table (only for admin or empty table)
                if (isAdmin)
                  IconButton(
                    onPressed: () => _deleteTable(table),
                    icon: const Icon(Icons.delete_outline, color: AppTheme.textSecondary, size: 22),
                    tooltip: 'Hapus Meja',
                  ),
              ],
            ),
            const Divider(height: 18),
            // Status Toggle Action Button (Kasir & Admin can toggle!)
            Row(
              children: [
                Expanded(
                  child: isAvailable
                      ? OutlinedButton.icon(
                          onPressed: () => _updateTableStatus(table, 'occupied'),
                          icon: const Icon(Icons.person, size: 16, color: AppTheme.warmindoRed),
                          label: const Text(
                            'Tandai Terisi (Pelanggan Duduk)',
                            style: TextStyle(color: AppTheme.warmindoRed, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.warmindoRed),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () => _updateTableStatus(table, 'available'),
                          icon: const Icon(Icons.cleaning_services, size: 16, color: Colors.white),
                          label: const Text(
                            'Kosongkan Meja (Pelanggan Pulang)',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.warmindoGreen,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final Color? color;

  const _TableFilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.warmindoRed;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: chipColor.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? chipColor : AppTheme.textPrimary,
      ),
      side: BorderSide(
        color: isSelected ? chipColor : AppTheme.dividerColor,
      ),
    );
  }
}
