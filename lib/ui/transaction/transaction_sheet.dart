import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/format_helpers.dart';
import '../../core/widgets/error_widgets.dart';

import '../../data/local/models/business_model.dart';
import '../../data/local/models/category_model.dart';
import '../../data/remote/supabase_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';

import '../../core/theme/app_icon_size.dart';

/// Smart Transaction Sheet with real-time IDR currency formatting.
class TransactionSheet extends ConsumerStatefulWidget {
  final BusinessModel business;
  final bool startAsIncome; // optional: pre-select tab

  const TransactionSheet({
    super.key,
    required this.business,
    this.startAsIncome = true,
  });

  static Future<void> show(BuildContext context, BusinessModel business, {bool startAsIncome = true}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProviderScope(
        overrides: [],
        child: TransactionSheet(business: business, startAsIncome: startAsIncome),
      ),
    );
  }

  @override
  ConsumerState<TransactionSheet> createState() => _TransactionSheetState();
}

class _TransactionSheetState extends ConsumerState<TransactionSheet> {
  int _selectedTabIndex = 0;

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _cogsController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  String _paymentMethod = AppConstants.paymentCash;
  bool _isSaving = false;

  final _dateTextController = TextEditingController();

  // Currency formatting state
  bool _isFormattingAmount = false;
  bool _isFormattingCogs = false;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.startAsIncome ? 0 : 1;
    _dateTextController.text = _formatDate(_selectedDate);
    _loadCategories();

    // Add listeners for IDR formatting
    _amountController.addListener(_onAmountChanged);
    _cogsController.addListener(_onCogsChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _cogsController.removeListener(_onCogsChanged);
    _amountController.dispose();
    _cogsController.dispose();
    _descriptionController.dispose();
    _dateTextController.dispose();
    super.dispose();
  }

  /// Real-time IDR formatting for amount field
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

  /// Real-time IDR formatting for COGS field
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
      if (i > 0 && (s.length - i) % 3 == 0) {
        result.write('.');
      }
      result.write(s[i]);
    }
    return result.toString();
  }

  String get _selectedType =>
      _selectedTabIndex == 0
          ? AppConstants.typeIncome
          : AppConstants.typeExpense;

  bool get _isIncome => _selectedTabIndex == 0;

  Future<void> _loadCategories() async {
    try {
      final categories = await SupabaseService.instance.getCategoriesByType(
        widget.business.businessId,
        _selectedType,
      );
      if (mounted) {
        setState(() {
          categories.sort((a, b) {
            if (a.name == 'Lain-lain') return 1;
            if (b.name == 'Lain-lain') return -1;
            return 0;
          });
          _categories = categories;
          if (_categories.isNotEmpty && _selectedCategory == null) {
            _selectedCategory = _categories.first;
          } else if (_selectedCategory != null) {
            final stillValid =
                _categories.any((c) => c.categoryId == _selectedCategory!.categoryId);
            if (!stillValid) {
              _selectedCategory =
                  _categories.isNotEmpty ? _categories.first : null;
            }
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

  void _onTabChanged(int index) {
    setState(() {
      _selectedTabIndex = index;
      _selectedCategory = null;
      _cogsController.clear();
    });
    _loadCategories();
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
      ErrorSnackbar.showWarning(
          context, 'Pilih kategori terlebih dahulu');
      return;
    }

    setState(() => _isSaving = true);

    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() => _isSaving = false);
      ErrorSnackbar.showError(
          context, 'Sesi tidak valid, silakan login ulang');
      return;
    }

    final amountStr = _amountController.text.replaceAll('.', '');
    final amount = double.tryParse(amountStr) ?? 0;
    final cogsStr = _cogsController.text.replaceAll('.', '');
    final cogs = _isIncome
        ? (double.tryParse(cogsStr) ?? 0)
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
      ErrorSnackbar.showSuccess(
          context, result.message ?? 'Berhasil');
      triggerTransactionRefresh(ref);
      Navigator.of(context).pop();
    } else {
      ErrorSnackbar.showError(
          context, result.message ?? 'Gagal');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColorTheme(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.radiusXL)),
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
                color: AppTheme.outlineVariantColorTheme(context),
                borderRadius: BorderRadius.circular(AppRadius.s2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s20, AppSpacing.s16, AppSpacing.s20, 0),
              child: Row(
                children: [
                  Text('Tambah Transaksi', style: AppTheme.heading2),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
              child: Text(
                widget.business.name,
                style: AppTheme.caption,
              ),
            ),

            const SizedBox(height: AppSpacing.s16),

             // Segmented tab
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.outlineVariantColorTheme(context).withValues(alpha: 0.15)
                      : AppTheme.outlineVariantColorTheme(context).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
                ),
                child: Row(
                  children: [
                    // Tab 0: Uang Masuk (Income)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _onTabChanged(0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s10),
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 0
                                ? AppTheme.profitColorTheme(context)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.trending_up_rounded,
                                size: AppIconSize.s18,
                                color: _selectedTabIndex == 0
                                    ? Colors.white
                                    : AppTheme.onSurfaceVariantColorTheme(context),
                              ),
                              const SizedBox(width: AppSpacing.s8),
                              Text(
                                'Uang Masuk',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: _selectedTabIndex == 0 ? FontWeight.w600 : FontWeight.normal,
                                  color: _selectedTabIndex == 0
                                      ? Colors.white
                                      : AppTheme.onSurfaceVariantColorTheme(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Tab 1: Uang Keluar (Expense)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _onTabChanged(1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s10),
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 1
                                ? AppTheme.lossColorTheme(context)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.trending_down_rounded,
                                size: AppIconSize.s18,
                                color: _selectedTabIndex == 1
                                    ? Colors.white
                                    : AppTheme.onSurfaceVariantColorTheme(context),
                              ),
                              const SizedBox(width: AppSpacing.s8),
                              Text(
                                'Uang Keluar',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: _selectedTabIndex == 1 ? FontWeight.w600 : FontWeight.normal,
                                  color: _selectedTabIndex == 1
                                      ? Colors.white
                                      : AppTheme.onSurfaceVariantColorTheme(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.s20),

            // Scrollable form
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(AppSpacing.s20, 0, AppSpacing.s20, bottomInset + AppSpacing.s20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FormLabel('Kategori'),
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

                    _FormLabel('Tanggal Transaksi'),
                    const SizedBox(height: AppSpacing.s8),
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

                    const SizedBox(height: AppSpacing.s20),

                    // Amount with IDR formatting
                    _FormLabel(
                      'Jumlah (Rp)',
                      subtitle: _selectedType == AppConstants.typeIncome
                          ? 'Wajib diisi'
                          : 'Wajib diisi',
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
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

                    // COGS (only for income)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      child: _selectedType == AppConstants.typeIncome
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: AppSpacing.s20),
                                _FormLabel(
                                  'HPP (Harga Pokok Penjualan)',
                                  subtitle:
                                      'Opsional - modal/harga beli barang',
                                ),
                                const SizedBox(height: AppSpacing.s8),
                                TextFormField(
                                  controller: _cogsController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: const InputDecoration(
                                    prefixIcon:
                                        Icon(Icons.inventory_2_outlined),
                                    hintText: '0',
                                    prefixText: 'Rp ',
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: AppSpacing.s20),

                    _FormLabel('Metode Pembayaran'),
                    const SizedBox(height: AppSpacing.s8),
                    DropdownButtonFormField<String>(
                      initialValue: _paymentMethod,
                      isDense: true,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        prefixIcon: Icon(Icons.payment_outlined),
                      ),
                      style: AppTheme.bodyText.copyWith(
                        color: AppTheme.onSurfaceColorTheme(context),
                      ),
                      iconEnabledColor: AppTheme.onSurfaceColorTheme(context),
                      dropdownColor: AppTheme.surfaceColorTheme(context),
                      items: [
                        DropdownMenuItem(
                          value: AppConstants.paymentCash,
                          child: Row(
                            children: [
                              Icon(Icons.money_rounded, size: 20, color: AppTheme.onSurfaceColorTheme(context)),
                              const SizedBox(width: AppSpacing.s8),
                              Text('Tunai', style: AppTheme.bodyText.copyWith(color: AppTheme.onSurfaceColorTheme(context))),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: AppConstants.paymentTransfer,
                          child: Row(
                            children: [
                              Icon(Icons.account_balance_rounded, size: 20, color: AppTheme.onSurfaceColorTheme(context)),
                              const SizedBox(width: AppSpacing.s8),
                              Text('Transfer Bank', style: AppTheme.bodyText.copyWith(color: AppTheme.onSurfaceColorTheme(context))),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: AppConstants.paymentQris,
                          child: Row(
                            children: [
                              Icon(Icons.qr_code_rounded, size: 20, color: AppTheme.onSurfaceColorTheme(context)),
                              const SizedBox(width: AppSpacing.s8),
                              Text('QRIS', style: AppTheme.bodyText.copyWith(color: AppTheme.onSurfaceColorTheme(context))),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'other',
                          child: Row(
                            children: [
                              Icon(Icons.more_horiz_rounded, size: 20, color: AppTheme.onSurfaceColorTheme(context)),
                              const SizedBox(width: AppSpacing.s8),
                              Text('Lainnya', style: AppTheme.bodyText.copyWith(color: AppTheme.onSurfaceColorTheme(context))),
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

                    const SizedBox(height: AppSpacing.s20),

                    _FormLabel('Deskripsi (opsional)'),
                    const SizedBox(height: AppSpacing.s8),
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

                    const SizedBox(height: AppSpacing.s16),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _handleSave,
                        icon: _isSaving
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.onPrimaryColorTheme(context),
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
                          style: AppTheme.buttonText.copyWith(fontSize: 16),
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
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurfaceColorTheme(context),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.s2),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppTheme.onSurfaceVariantColorTheme(context),
            ),
          ),
        ],
      ],
    );
  }
}
