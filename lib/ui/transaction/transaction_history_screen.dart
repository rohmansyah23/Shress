import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/database.dart';
import '../../data/local/models/business_model.dart';
import '../../data/local/models/transaction_model.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  final BusinessModel business;

  const TransactionHistoryScreen({super.key, required this.business});

  @override
  ConsumerState<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends ConsumerState<TransactionHistoryScreen> {
  final _searchCtrl = TextEditingController();
  List<TransactionModel> _all = [];
  List<TransactionModel> _filtered = [];

  @override
  void initState() {
    super.initState();
    final db = LocalDatabase.instance;
    _all = db.getTransactionsByBusiness(widget.business.businessId);
    _filtered = List.from(_all.reversed);
  }

  void _applySearch(String q) {
    setState(() {
      if (q.trim().isEmpty) {
        _filtered = List.from(_all.reversed);
      } else {
        _filtered = _all.reversed
            .where((t) => (t.description ?? '').toLowerCase().contains(q.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Cari deskripsi atau catatan...',
                border: OutlineInputBorder(),
              ),
              onChanged: _applySearch,
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('Tidak ada transaksi', style: AppTheme.heading3.copyWith(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final tx = _filtered[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            tx.type == 'income' ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: tx.type == 'income' ? AppTheme.profitColor : AppTheme.lossColor,
                          ),
                          title: Text('${tx.amount.toStringAsFixed(0)}'),
                          subtitle: Text(tx.description ?? tx.transactionDate),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(tx.transactionDate, style: AppTheme.caption),
                              if (!tx.statusSync) const Text('Pending', style: TextStyle(color: Colors.orange, fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
