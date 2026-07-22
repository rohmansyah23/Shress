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
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

import '../../core/theme/app_icon_size.dart';
import '../../core/utils/format_helpers.dart';

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
  final _dateTextController = TextEditingController();
  final _amountFocusNode = FocusNode();
  final _cogsFocusNode = FocusNode();
  bool _isSaving = false;
  bool _isFormattingAmount = false;
  bool _isFormattingCogs = false;

  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountController.text = _formatRupiah(widget.transaction.amount.toInt());
    _cogsController.text = _formatRupiah(widget.transaction.cogs.toInt());
    _descController.text = widget.transaction.description ?? '';

    final dateParts = widget.transaction.transactionDate.split('-');
    if (dateParts.length == 3) {
      _selectedDate = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
      );
    }
    _dateTextController.text = _formatDate(_selectedDate);

    _amountController.addListener(_onAmountChanged);
    _cogsController.addListener(_onCogsChanged);
    _amountFocusNode.addListener(_onAmountFocusChanged);
    _cogsFocusNode.addListener(_onCogsFocusChanged);
    _loadCategories();
  }

  void _onAmountFocusChanged() {
    if (_amountFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (_amountFocusNode.hasFocus && mounted && _amountFocusNode.context != null) {
          Scrollable.ensureVisible(
            _amountFocusNode.context!,
            alignment: 0.15,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  void _onCogsFocusChanged() {
    if (_cogsFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (_cogsFocusNode.hasFocus && mounted && _cogsFocusNode.context != null) {
          Scrollable.ensureVisible(
            _cogsFocusNode.context!,
            alignment: 0.15,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _amountFocusNode.removeListener(_onAmountFocusChanged);
    _cogsFocusNode.removeListener(_onCogsFocusChanged);
    _amountFocusNode.dispose();
    _cogsFocusNode.dispose();
    _amountController.removeListener(_onAmountChanged);
    _cogsController.removeListener(_onCogsChanged);
    _amountController.dispose();
    _cogsController.dispose();
    _descController.dispose();
    _dateTextController.dispose();
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
          categories.sort((a, b) {
            if (a.name == 'Lain-lain') return 1;
            if (b.name == 'Lain-lain') return -1;
            return 0;
          });
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
    return FormatHelpers.displayDate(
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}');
  }

  String _formatDateIso(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
      transactionDate: _formatDateIso(_selectedDate),
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
          padding: const EdgeInsets.all(AppSpacing.s20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: (isIncome
                          ? AppTheme.profitColorTheme(context)
                          : AppTheme.lossColorTheme(context))
                      .withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
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
                      size: AppIconSize.s28,
                    ),
                    const SizedBox(width: AppSpacing.s12),
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
                        const SizedBox(height: AppSpacing.s2),
                        Text(
                          widget.business.name,
                          style: AppTheme.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s24),

              Text(
                'Kategori',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceColorTheme(context),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              DropdownButtonFormField<CategoryModel>(
                initialValue: _selectedCategory,
                isDense: true,
                isExpanded: true,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.onSurfaceColorTheme(context),
                ),
                iconEnabledColor: AppTheme.onSurfaceColorTheme(context),
                dropdownColor: AppTheme.surfaceColorTheme(context),
                borderRadius: BorderRadius.circular(16),
                items: _categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(
                      cat.name,
                      style: AppTheme.bodyText.copyWith(
                        color: AppTheme.onSurfaceColorTheme(context),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedCategory = value),
                validator: (value) =>
                    value == null ? 'Pilih kategori' : null,
              ),

              const SizedBox(height: AppSpacing.s20),

              Text(
                'Tanggal Transaksi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceColorTheme(context),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              TextFormField(
                controller: _dateTextController,
                readOnly: true,
                onTap: _pickDate,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
              ),

              const SizedBox(height: AppSpacing.s20),

              Text(
                'Jumlah (Rp)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceColorTheme(context),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              TextFormField(
                controller: _amountController,
                focusNode: _amountFocusNode,
                scrollPadding: const EdgeInsets.only(bottom: 120),
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
                const SizedBox(height: AppSpacing.s20),
                Text(
                  'HPP (Harga Pokok Penjualan)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceColorTheme(context),
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                TextFormField(
                  controller: _cogsController,
                  focusNode: _cogsFocusNode,
                  scrollPadding: const EdgeInsets.only(bottom: 120),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                    hintText: '0',
                    prefixText: 'Rp ',
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.s20),
              Text(
                'Deskripsi (opsional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceColorTheme(context),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
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
