import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format_helpers.dart';

class OwnerActivityLogsScreen extends StatefulWidget {
  const OwnerActivityLogsScreen({super.key});

  @override
  State<OwnerActivityLogsScreen> createState() => _OwnerActivityLogsScreenState();
}

class _OwnerActivityLogsScreenState extends State<OwnerActivityLogsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await _supabase
          .from('owner_activity_logs')
          .select('*, businesses(name)')
          .order('created_at', ascending: false)
          .limit(100);

      setState(() {
        _logs = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat log aktivitas: $e';
      });
    }
  }

  IconData _getLogIcon(String tableName, String actionType) {
    if (tableName == 'transactions') {
      return Icons.receipt_long_rounded;
    } else if (tableName == 'debts') {
      return Icons.payment_rounded;
    } else {
      return Icons.inventory_2_rounded;
    }
  }

  Color _getLogIconColor(BuildContext context, String tableName, String actionType) {
    if (actionType == 'DELETE') {
      return AppTheme.lossColorTheme(context);
    }
    if (tableName == 'transactions') {
      return AppTheme.primaryColorTheme(context);
    } else if (tableName == 'debts') {
      return AppTheme.warningColorTheme(context);
    } else {
      return AppTheme.consignmentColorTheme(context);
    }
  }

  String _formatLogDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) {
        return 'Baru saja';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes} menit yang lalu';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} jam yang lalu';
      } else if (diff.inDays == 1) {
        return 'Kemarin, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else {
        return '${date.day} ${FormatHelpers.displayDate(dateStr).split(' ')[1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kotak Masuk Aktivitas'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                        const SizedBox(height: AppSpacing.s16),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: AppSpacing.s16),
                        ElevatedButton(
                          onPressed: _fetchLogs,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : _logs.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.s32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              size: 48,
                              color: AppTheme.onSurfaceVariantColorTheme(context).withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: AppSpacing.s16),
                            Text(
                              'Belum ada aktivitas tercatat',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.onSurfaceVariantColorTheme(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchLogs,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.s8),
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          final business = log['businesses'] as Map<String, dynamic>?;
                          final businessName = business?['name'] as String? ?? 'Bisnis';
                          final dateStr = log['created_at'] as String;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 4,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.s12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _getLogIconColor(context, log['table_name'], log['action_type']).withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _getLogIcon(log['table_name'], log['action_type']),
                                      size: 18,
                                      color: _getLogIconColor(context, log['table_name'], log['action_type']),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.s12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                log['title'] as String? ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: AppSpacing.s8),
                                            Text(
                                              _formatLogDate(dateStr),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: AppTheme.onSurfaceVariantColorTheme(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          log['body'] as String? ?? '',
                                          style: const TextStyle(
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          businessName,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.onSurfaceVariantColorTheme(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
