import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/widgets/error_widgets.dart';
import '../../data/local/models/business_model.dart';
import '../../data/local/models/category_model.dart';
import '../../data/local/models/transaction_model.dart';
import '../../data/remote/supabase_service.dart';
import '../../providers/transaction_provider.dart';

class EditTransactionPage extends StatefulWidget {
  final TransactionModel transaction;
  final BusinessModel business;

  const EditTransactionPage({
    super.key,
    required this.transaction,
    required this.business,
  });

  @override
  State<EditTransactionPage> createState() => _EditTransactionPageState();
}

class _EditTransactionPageState extends State<EditTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _cogsController = TextEditingController();
  final _descController = TextEditingController();
  bool _isSaving = false;
  bool _isFormattingAmount = false;
  bool _isFormattingCogs = false;

  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _amountController.text = _formatRupiah(widget.transaction.amount.toInt());
    _cogsController.text = _formatRupiah(widget.transaction.cogs.toInt());
    _descController.text = widget.transaction.description ?? '';
    _amountController.addListener(_onAmountChanged);
    _cogsController.addListener(_onCogsChanged);
    _loadCategories();
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _cogsController.removeListener(_onCogsChanged);
    _amountController.dispose();
    _cogsController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final isIncome = widget.transaction.type == AppConstants.typeIncome;
      final categories = await SupabaseService.instance.getCategoriesByType(
        widget.business.businessId,
        isIncome ? AppConstants.typeIncome : AppConstants.typeExpense,
      );
      if (mounted) {
        setState(() {
          _categories = categories;
          _selectedCategory = _categories.firstWhere(
            (c) => c.categoryId == widget.transaction.categoryId,
            orElse: () => _categories.isNotEmpty
                ? _categories.first
                : CategoryModel(
                    categoryId: 0,
                    businessId: 0,
                    name: '',
                    type: '',
                  ),
          );
          if (_selectedCategory!.categoryId == 0) {
            _selectedCategory =
                _categories.isNotEmpty ? _categories.first : null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        final error = ErrorHandler.classify(e);
        ErrorSnackbar.show(context, error);
      }
    }
  }

  void _onAmountChanged() {
    if (_isFormattingAmount) return;
    _isFormattingAmount = true;
    final text = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.isNotEmpty) {
      final value = int.tryParse(text) ?? 0;
      final formatted = _formatRupiah(value);
      if (_amountController.text != formatted) {
        _amountController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }
    _isFormattingAmount = false;
  }

  void _onCogsChanged() {
    if (_isFormattingCogs) return;
    _isFormattingCogs = true;
    final text = _cogsController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.isNotEmpty) {
      final value = int.tryParse(text) ?? 0;
      final formatted = _formatRupiah(value);
      if (_cogsController.text != formatted) {
        _cogsController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }
    _isFormattingCogs = false;
  }

  String _formatRupiah(int value) {
    final s = value.toString();
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write('.');
      result.write(s[i]);
    }
    return result.toString();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ErrorSnackbar.showWarning(context, 'Pilih kategori terlebih dahulu');
      return;
    }
    setState(() => _isSaving = true);

    final amountStr = _amountController.text.replaceAll('.', '');
    final amount = double.tryParse(amountStr) ?? 0;
    final isIncome = widget.transaction.type == AppConstants.typeIncome;
    final cogsStr = _cogsController.text.replaceAll('.', '');
    final cogs = isIncome ? (double.tryParse(cogsStr) ?? 0) : 0.0;

    final result = await updateTransaction(
      transactionId: widget.transaction.transactionId!,
      categoryId: _selectedCategory!.categoryId,
      amount: amount,
      cogs: isIncome ? cogs : null,
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.success) {
      ErrorSnackbar.showSuccess(
          context, result.message ?? 'Berhasil diperbarui');
      Navigator.of(context).pop(true);
    } else {
      ErrorSnackbar.showError(
          context, result.message ?? 'Gagal memperbarui');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.transaction.type == AppConstants.typeIncome;

    return Scaffold(
      appBar: AppBar(
        title: Text(isIncome ? 'Edit Uang Masuk' : 'Edit Uang Keluar'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _handleSave,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan',
                    style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.s20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.s16),
                decoration: BoxDecoration(
                  color: (isIncome
                          ? AppTheme.profitColorTheme(context)
                          : AppTheme.lossColorTheme(context))
                      .withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(
                    color: (isIncome
                            ? AppTheme.profitColorTheme(context)
                            : AppTheme.lossColorTheme(context))
                        .withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isIncome
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: isIncome
                          ? AppTheme.profitColorTheme(context)
                          : AppTheme.lossColorTheme(context),
                      size: 28,
                    ),
                    const SizedBox(width: AppTheme.s12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isIncome ? 'UANG MASUK' : 'UANG KELUAR',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: isIncome
                                ? AppTheme.profitColorTheme(context)
                                : AppTheme.lossColorTheme(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.business.name,
                          style: AppTheme.caption.copyWith(fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.s24),

              const Text('Kategori',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppTheme.s8),
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

              const SizedBox(height: AppTheme.s20),

              const Text('Jumlah (Rp)',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppTheme.s8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.monetization_on_outlined),
                  hintText: '0',
                  prefixText: 'Rp ',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Masukkan jumlah';
                  }
                  final numeric = value.replaceAll('.', '');
                  final amount = double.tryParse(numeric);
                  if (amount == null || amount <= 0) {
                    return 'Jumlah harus lebih dari 0';
                  }
                  return null;
                },
              ),

              if (isIncome) ...[
                const SizedBox(height: AppTheme.s20),
                const Text('HPP (Harga Pokok Penjualan)',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: AppTheme.s8),
                TextFormField(
                  controller: _cogsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                    hintText: '0',
                    prefixText: 'Rp ',
                  ),
                ),
              ],

              const SizedBox(height: AppTheme.s20),
              const Text('Deskripsi (opsional)',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppTheme.s8),
              TextFormField(
                controller: _descController,
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
            ],
          ),
        ),
      ),
    );
  }
}
