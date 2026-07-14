import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/format_helpers.dart';
import '../../core/widgets/error_widgets.dart';
import '../../data/local/models/business_model.dart';
import '../../data/local/models/debtor_model.dart';
import '../../data/remote/supabase_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/debt_consignment_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/debtor_provider.dart';

class AddDebtScreen extends ConsumerStatefulWidget {
  final BusinessModel business;
  final DebtorModel? existingDebtor;

  const AddDebtScreen({
    super.key,
    required this.business,
    this.existingDebtor,
  });

  @override
  ConsumerState<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends ConsumerState<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _debtDateController = TextEditingController();
  final _dueDateController = TextEditingController();

  DateTime _debtDate = DateTime.now();
  DateTime? _dueDate;
  bool _isSaving = false;
  bool _isFormattingAmount = false;
  DebtorModel? _selectedDebtor;

  bool get _hasSelectedDebtor => _selectedDebtor != null;

  @override
  void initState() {
    super.initState();
    _selectedDebtor = widget.existingDebtor;
    if (_selectedDebtor != null) {
      _nameController.text = _selectedDebtor!.name;
    }
    _debtDateController.text = _formatDate(_debtDate);
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _debtDateController.dispose();
    _dueDateController.dispose();
    super.dispose();
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

  String _formatDate(DateTime date) {
    return FormatHelpers.displayDate(
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}');
  }

  String _formatDateIso(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDebtDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _debtDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Pilih Tanggal Hutang',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked != null) {
      setState(() {
        _debtDate = picked;
        _debtDateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Pilih Jatuh Tempo',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
        _dueDateController.text = _formatDate(picked);
      });
    }
  }

  void _clearDueDate() {
    setState(() {
      _dueDate = null;
      _dueDateController.clear();
    });
  }

  void _showDebtorSelectionSheet() {
    final debtorsAsync = ref.read(debtorProvider(widget.business.businessId));
    final debtorsList = debtorsAsync.value?.debtors ?? [];

    if (debtorsList.isEmpty) {
      ErrorSnackbar.showMessage(
        context,
        'Belum ada penghutang terdaftar untuk bisnis ini.',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filteredDebtors = debtorsList.where((d) =>
              d.name.toLowerCase().contains(searchQuery.toLowerCase())
            ).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Text('Pilih Penghutang', style: AppTheme.heading3),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Cari nama penghutang...',
                        prefixIcon: Icon(Icons.search_rounded),
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                      onChanged: (val) {
                        setSheetState(() {
                          searchQuery = val;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: filteredDebtors.isEmpty
                        ? Center(
                            child: Text(
                              'Tidak ada hasil pencarian',
                              style: AppTheme.caption,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: filteredDebtors.length,
                            itemBuilder: (context, index) {
                              final debtor = filteredDebtors[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppTheme.warningColorTheme(context).withValues(alpha: 0.12),
                                    child: Text(
                                      debtor.name.isNotEmpty ? debtor.name[0].toUpperCase() : '?',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.warningColorTheme(context),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    debtor.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: debtor.phone != null && debtor.phone!.isNotEmpty
                                      ? Text(debtor.phone!)
                                      : null,
                                  onTap: () {
                                    setState(() {
                                      _selectedDebtor = debtor;
                                    });
                                    Navigator.pop(ctx);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() => _isSaving = false);
      if (mounted) {
        ErrorSnackbar.showError(
            context, 'Sesi tidak valid, silakan login ulang');
      }
      return;
    }

    try {
      int debtorId;

      if (_hasSelectedDebtor) {
        debtorId = _selectedDebtor!.id;
      } else {
        final debtor = await SupabaseService.instance.createDebtor(
          businessId: widget.business.businessId,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
        debtorId = debtor.id;
      }

      final amountStr = _amountController.text.replaceAll('.', '');
      final amount = double.tryParse(amountStr) ?? 0;

      final expenseCategoryId =
          await SupabaseService.instance.getOrCreateCategoryForBusiness(
        widget.business.businessId,
        AppConstants.categoryPiutang,
        AppConstants.typeExpense,
      );

      await SupabaseService.instance.createDebt(
        debtorId: debtorId,
        businessId: widget.business.businessId,
        userId: user.userId,
        amount: amount,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        debtDate: _formatDateIso(_debtDate),
        dueDate: _dueDate != null ? _formatDateIso(_dueDate!) : null,
        expenseCategoryId: expenseCategoryId,
      );

      setState(() => _isSaving = false);

      if (!mounted) return;
      triggerDebtRefresh(ref);
      triggerTransactionRefresh(ref);
      Navigator.of(context).pop(true);
      ErrorSnackbar.showSuccess(context, 'Hutang berhasil disimpan');
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ErrorSnackbar.show(context, ErrorHandler.classify(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Hutang Baru'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_hasSelectedDebtor) ...[
                Text('Data Penghutang', style: AppTheme.heading3),
                const SizedBox(height: AppTheme.s16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.infoColorTheme(context)
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_rounded,
                        size: 20,
                        color: AppTheme.infoColorTheme(context),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedDebtor!.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_selectedDebtor!.phone != null &&
                                _selectedDebtor!.phone!.isNotEmpty)
                              Text(
                                _selectedDebtor!.phone!,
                                style: AppTheme.caption.copyWith(fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      if (widget.existingDebtor == null)
                        IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: Theme.of(context).colorScheme.onSurfaceVariant),
                          onPressed: () {
                            setState(() {
                              _selectedDebtor = null;
                            });
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.s24),
              ],
              if (!_hasSelectedDebtor) ...[
                Text('Data Penghutang', style: AppTheme.heading3),
                const SizedBox(height: AppTheme.s16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.people_alt_outlined),
                  label: const Text('Pilih dari Penghutang Terdaftar'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                  onPressed: _showDebtorSelectionSheet,
                ),
                const SizedBox(height: AppTheme.s16),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'ATAU BUAT BARU',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: AppTheme.s16),
                _FormLabel('Nama Penghutang *'),
                const SizedBox(height: AppTheme.s8),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person_outline_rounded),
                    hintText: 'Nama penghutang baru',
                  ),
                  validator: (value) {
                    if (_hasSelectedDebtor) return null;
                    if (value == null || value.trim().isEmpty) {
                      return 'Masukkan nama penghutang';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.s20),
                _FormLabel('Nomor Telepon (opsional)'),
                const SizedBox(height: AppTheme.s8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: '08xxxxxxxxxx',
                  ),
                ),
                const SizedBox(height: AppTheme.s20),
                _FormLabel('Catatan (opsional)'),
                const SizedBox(height: AppTheme.s8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Catatan tentang penghutang...',
                  ),
                ),
                const SizedBox(height: AppTheme.s24),
                const Divider(),
                const SizedBox(height: AppTheme.s16),
              ],
              Text('Detail Hutang', style: AppTheme.heading3),
              const SizedBox(height: AppTheme.s16),
              _FormLabel('Jumlah Hutang (Rp) *'),
              const SizedBox(height: AppTheme.s8),
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
                    return 'Masukkan jumlah hutang';
                  }
                  final numeric = value.replaceAll('.', '');
                  final amount = double.tryParse(numeric);
                  if (amount == null || amount <= 0) {
                    return 'Jumlah harus lebih dari 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.s20),
              _FormLabel('Deskripsi (opsional)'),
              const SizedBox(height: AppTheme.s8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Deskripsi hutang...',
                ),
              ),
              const SizedBox(height: AppTheme.s20),
              _FormLabel('Tanggal Hutang'),
              const SizedBox(height: AppTheme.s8),
              TextFormField(
                controller: _debtDateController,
                readOnly: true,
                onTap: _pickDebtDate,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
              ),
              const SizedBox(height: AppTheme.s20),
              Row(
                children: [
                  Expanded(
                    child: _FormLabel('Jatuh Tempo (opsional)'),
                  ),
                  if (_dueDate != null)
                    TextButton(
                      onPressed: _clearDueDate,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Hapus', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.s8),
              TextFormField(
                controller: _dueDateController,
                readOnly: true,
                onTap: _pickDueDate,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.event_outlined),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                  hintText: 'Pilih jatuh tempo (opsional)',
                ),
              ),
              const SizedBox(height: AppTheme.s32),
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
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _isSaving ? 'Menyimpan...' : 'Simpan Hutang',
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
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String label;

  const _FormLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
