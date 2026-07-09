import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/database.dart';
import '../../data/local/models/business_model.dart';
import '../../data/local/models/category_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';

/// Smart Transaction Sheet — dual-tab Income/Expense form with dynamic COGS input.
class TransactionSheet extends ConsumerStatefulWidget {
  final BusinessModel business;

  const TransactionSheet({super.key, required this.business});

  /// Open the transaction sheet as a modal bottom sheet
  static Future<void> show(BuildContext context, BusinessModel business) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProviderScope(
        overrides: [],
        child: TransactionSheet(business: business),
      ),
    );
  }

  @override
  ConsumerState<TransactionSheet> createState() => _TransactionSheetState();
}

class _TransactionSheetState extends ConsumerState<TransactionSheet> {
  // Tab state
  int _selectedTabIndex = 0; // 0 = Income, 1 = Expense

  // Form state
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _cogsController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Data
  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  String _paymentMethod = 'cash';
  bool _isSaving = false;

  // Controllers for date & payment picker
  final _dateTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dateTextController.text = _formatDate(_selectedDate);
    _loadCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _cogsController.dispose();
    _descriptionController.dispose();
    _dateTextController.dispose();
    super.dispose();
  }

  String get _selectedType =>
      _selectedTabIndex == 0 ? AppConstants.typeIncome : AppConstants.typeExpense;

  bool get _isIncome => _selectedTabIndex == 0;

  void _loadCategories() {
    _categories = LocalDatabase.instance
        .getCategoriesByType(widget.business.businessId, _selectedType);
    if (_categories.isNotEmpty && _selectedCategory == null) {
      _selectedCategory = _categories.first;
    } else if (_selectedCategory != null) {
      // Verify selected category still valid for this tab
      final stillValid =
          _categories.any((c) => c.categoryId == _selectedCategory!.categoryId);
      if (!stillValid) {
        _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
      }
    }
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedTabIndex = index;
      _selectedCategory = null;
      _cogsController.clear();
      _loadCategories();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Pilih Tanggal Transaksi',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateTextController.text = _formatDate(picked);
      });
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateIso(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori terlebih dahulu')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi tidak valid, silakan login ulang')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    final cogs = _isIncome
        ? (double.tryParse(_cogsController.text.replaceAll(',', '')) ?? 0)
        : 0.0;

    final result = await saveTransaction(
      businessId: widget.business.businessId,
      categoryId: _selectedCategory!.categoryId,
      userId: user.userId,
      type: _selectedType,
      amount: amount,
      cogs: cogs,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      transactionDate: _formatDateIso(_selectedDate),
      paymentMethod: _paymentMethod,
    );

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (result.success) {
      // Trigger dashboard refresh
      triggerTransactionRefresh(ref);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Berhasil'),
          backgroundColor: AppTheme.profitColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Gagal'),
          backgroundColor: AppTheme.lossColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(
                    'Tambah Transaksi',
                    style: AppTheme.heading2,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Business name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                widget.business.name,
                style: AppTheme.caption.copyWith(fontSize: 13),
              ),
            ),

            const SizedBox(height: 16),

            // Segmented tab: Income / Expense
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      label: Text('Uang Masuk'),
                      icon: Icon(Icons.trending_up_rounded),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text('Uang Keluar'),
                      icon: Icon(Icons.trending_down_rounded),
                    ),
                  ],
                  selected: {_selectedTabIndex},
                  onSelectionChanged: (selected) => _onTabChanged(selected.first),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Scrollable form content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== Category Dropdown =====
                    _FormLabel('Kategori'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<CategoryModel>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat.name),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedCategory = value),
                      validator: (value) =>
                          value == null ? 'Pilih kategori' : null,
                    ),

                    const SizedBox(height: 20),

                    // ===== Date Picker =====
                    _FormLabel('Tanggal Transaksi'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _dateTextController,
                      readOnly: true,
                      onTap: _pickDate,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Pilih tanggal' : null,
                    ),

                    const SizedBox(height: 20),

                    // ===== Amount =====
                    _FormLabel(
                      'Jumlah (Rp)',
                      subtitle: _selectedType == AppConstants.typeIncome
                          ? 'Pendapatan'
                          : 'Pengeluaran',
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.monetization_on_outlined),
                        hintText: '0',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Masukkan jumlah';
                        }
                        final amount = double.tryParse(value.replaceAll(',', ''));
                        if (amount == null || amount <= 0) {
                          return 'Jumlah harus lebih dari 0';
                        }
                        return null;
                      },
                    ),

                    // ===== COGS (Income only - dynamic) =====
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _isIncome
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
                                _FormLabel(
                                  'HPP (Harga Pokok Penjualan)',
                                  subtitle: 'Modal barang yang terjual',
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _cogsController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.inventory_2_outlined),
                                    hintText: '0',
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 20),

                    // ===== Payment Method =====
                    _FormLabel('Metode Pembayaran'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _paymentMethod,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.payment_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'cash',
                          child: Row(
                            children: [
                              Icon(Icons.money_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Tunai'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'transfer',
                          child: Row(
                            children: [
                              Icon(Icons.account_balance_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Transfer Bank'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'qris',
                          child: Row(
                            children: [
                              Icon(Icons.qr_code_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('QRIS'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'other',
                          child: Row(
                            children: [
                              Icon(Icons.more_horiz_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Lainnya'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _paymentMethod = value);
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    // ===== Description =====
                    _FormLabel('Deskripsi (opsional)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 48),
                          child: Icon(Icons.description_outlined),
                        ),
                        hintText: 'Catatan tambahan...',
                        alignLabelWithHint: true,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ===== Save Button =====
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _handleSave,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                _isIncome
                                    ? Icons.trending_up_rounded
                                    : Icons.trending_down_rounded,
                              ),
                        label: Text(
                          _isSaving
                              ? 'Menyimpan...'
                              : _isIncome
                                  ? 'Simpan Uang Masuk'
                                  : 'Simpan Uang Keluar',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small form label widget
class _FormLabel extends StatelessWidget {
  final String label;
  final String? subtitle;

  const _FormLabel(this.label, {this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: AppTheme.caption.copyWith(fontSize: 11),
          ),
        ],
      ],
    );
  }
}
