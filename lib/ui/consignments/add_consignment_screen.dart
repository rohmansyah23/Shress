import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/format_helpers.dart';
import '../../core/widgets/error_widgets.dart';
import '../../data/local/models/business_model.dart';
import '../../data/local/models/consignor_model.dart';
import '../../data/remote/supabase_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/debt_consignment_provider.dart';

class AddConsignmentScreen extends ConsumerStatefulWidget {
  final BusinessModel business;
  final ConsignorModel? existingConsignor;

  const AddConsignmentScreen({
    super.key,
    required this.business,
    this.existingConsignor,
  });

  @override
  ConsumerState<AddConsignmentScreen> createState() =>
      _AddConsignmentScreenState();
}

class _ConsignmentItemEntry {
  final TextEditingController nameController;
  final TextEditingController qtyController;
  final TextEditingController priceController;
  final TextEditingController sellingPriceController;

  _ConsignmentItemEntry()
      : nameController = TextEditingController(),
        qtyController = TextEditingController(text: '1'),
        priceController = TextEditingController(),
        sellingPriceController = TextEditingController();

  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    priceController.dispose();
    sellingPriceController.dispose();
  }
}

class _AddConsignmentScreenState extends ConsumerState<AddConsignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _consignmentDate =
      DateTime.now().toIso8601String().substring(0, 10);
  String? _dueDate;
  final List<_ConsignmentItemEntry> _items = [_ConsignmentItemEntry()];

  ConsignorModel? _selectedConsignor;
  List<ConsignorModel> _existingConsignors = [];
  bool _useExistingConsignor = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingConsignor != null) {
      _selectedConsignor = widget.existingConsignor;
      _useExistingConsignor = true;
      _nameController.text = widget.existingConsignor!.name;
      _phoneController.text = widget.existingConsignor!.phone ?? '';
      _notesController.text = widget.existingConsignor!.notes ?? '';
    }
    _loadExistingConsignors();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _descriptionController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExistingConsignors() async {
    try {
      final data = await SupabaseService.instance
          .getConsignorsByBusiness(widget.business.businessId);
      if (mounted) {
        setState(() => _existingConsignors = data);
      }
    } catch (_) {}
  }

  void _addItem() {
    setState(() => _items.add(_ConsignmentItemEntry()));
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  double _calculateTotal() {
    double total = 0;
    for (final item in _items) {
      final qty = int.tryParse(item.qtyController.text) ?? 0;
      final price = double.tryParse(item.priceController.text) ?? 0;
      total += qty * price;
    }
    return total;
  }

  Future<void> _pickDate(bool isDueDate) async {
    final initial = isDueDate && _dueDate != null
        ? DateTime.parse(_dueDate!)
        : isDueDate
            ? DateTime.now().add(const Duration(days: 30))
            : DateTime.parse(_consignmentDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: isDueDate ? 'Pilih Jatuh Tempo' : 'Pilih Tanggal Titip',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );

    if (picked != null) {
      final dateStr = picked.toIso8601String().substring(0, 10);
      setState(() {
        if (isDueDate) {
          _dueDate = dateStr;
        } else {
          _consignmentDate = dateStr;
        }
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    for (final item in _items) {
      if (item.nameController.text.trim().isEmpty) {
        ErrorSnackbar.showMessage(context, 'Nama produk harus diisi');
        return;
      }
      if ((int.tryParse(item.qtyController.text) ?? 0) <= 0) {
        ErrorSnackbar.showMessage(context, 'Jumlah harus lebih dari 0');
        return;
      }
      if ((double.tryParse(item.priceController.text) ?? 0) <= 0) {
        ErrorSnackbar.showMessage(context, 'Harga harus lebih dari 0');
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        if (mounted) {
          setState(() => _isSaving = false);
          ErrorSnackbar.showMessage(context, 'Sesi tidak valid');
        }
        return;
      }

      ConsignorModel consignor;

      if (_useExistingConsignor && _selectedConsignor != null) {
        consignor = _selectedConsignor!;
      } else {
        consignor = await SupabaseService.instance.createConsignor(
          businessId: widget.business.businessId,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
      }

      final totalAmount = _calculateTotal();

      final consignmentId = await SupabaseService.instance.createConsignment(
        consignorId: consignor.id,
        businessId: widget.business.businessId,
        userId: user.userId,
        totalAmount: totalAmount,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        consignmentDate: _consignmentDate,
        dueDate: _dueDate,
      );

      for (final item in _items) {
        await SupabaseService.instance.addConsignmentItem(
          consignmentId: consignmentId,
          productName: item.nameController.text.trim(),
          quantity: int.tryParse(item.qtyController.text) ?? 1,
          agreedPrice: double.tryParse(item.priceController.text) ?? 0,
          sellingPrice:
              double.tryParse(item.sellingPriceController.text),
        );
      }

      if (!mounted) return;
      triggerDebtRefresh(ref);
      ErrorSnackbar.showSuccess(context, 'Titipan berhasil disimpan');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ErrorSnackbar.show(context, ErrorHandler.classify(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Titipan Baru'),
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
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildConsignorSection(),
            const SizedBox(height: 24),
            Text('Item Titipan', style: AppTheme.heading3),
            const SizedBox(height: 4),
            Text(
              'Tambahkan produk yang dititipkan',
              style: AppTheme.caption.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 12),
            ...List.generate(_items.length, (index) => _buildItemCard(index)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Tambah Item'),
            ),
            const SizedBox(height: 24),
            Text('Detail Tambahan', style: AppTheme.heading3),
            const SizedBox(height: 12),
            _buildDetailSection(),
            const SizedBox(height: 24),
            _buildDateSection(),
            const SizedBox(height: 32),
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
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Titipan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsignorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Data Penitip', style: AppTheme.heading3),
        const SizedBox(height: 12),
        if (_existingConsignors.isNotEmpty &&
            widget.existingConsignor == null) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  'Gunakan penitip yang sudah ada?',
                  style: AppTheme.caption.copyWith(fontSize: 13),
                ),
              ),
              Switch(
                value: _useExistingConsignor,
                onChanged: (v) {
                  setState(() {
                    _useExistingConsignor = v;
                    _selectedConsignor = null;
                    if (v && _existingConsignors.isNotEmpty) {
                      _selectedConsignor = _existingConsignors.first;
                      _nameController.text = _existingConsignors.first.name;
                      _phoneController.text =
                          _existingConsignors.first.phone ?? '';
                      _notesController.text =
                          _existingConsignors.first.notes ?? '';
                    } else {
                      _nameController.clear();
                      _phoneController.clear();
                      _notesController.clear();
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (_useExistingConsignor && _existingConsignors.isNotEmpty)
          DropdownButtonFormField<int>(
            initialValue: _selectedConsignor?.id,
            decoration: const InputDecoration(
              labelText: 'Pilih Penitip',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            items: _existingConsignors.map((c) {
              return DropdownMenuItem(value: c.id, child: Text(c.name));
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              final found =
                  _existingConsignors.firstWhere((c) => c.id == value);
              setState(() {
                _selectedConsignor = found;
                _nameController.text = found.name;
                _phoneController.text = found.phone ?? '';
                _notesController.text = found.notes ?? '';
              });
            },
          )
        else ...[
          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Nama Penitip *',
              prefixIcon: Icon(Icons.person_outline_rounded),
              hintText: 'Nama penitip',
            ),
            validator: (v) => v?.trim().isEmpty == true
                ? 'Nama penitip harus diisi'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Telepon (opsional)',
              prefixIcon: Icon(Icons.phone_outlined),
              hintText: 'Nomor telepon',
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Catatan (opsional)',
              prefixIcon: Icon(Icons.notes_outlined),
              hintText: 'Catatan tentang penitip',
            ),
            maxLines: 2,
          ),
        ],
      ],
    );
  }

  Widget _buildItemCard(int index) {
    final item = _items[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Item ${index + 1}',
                  style: AppTheme.labelSmall.copyWith(fontSize: 12),
                ),
                const Spacer(),
                if (_items.length > 1)
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        size: 18, color: AppTheme.lossColorTheme(context)),
                    onPressed: () => _removeItem(index),
                    tooltip: 'Hapus Item',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: item.nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nama Produk *',
                hintText: 'Contoh: Baju Merah',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: item.qtyController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah *',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: item.priceController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Harga Sepakat *',
                      prefixText: 'Rp ',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: item.sellingPriceController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Harga Jual (opsional)',
                prefixText: 'Rp ',
                hintText: 'Harga jual ke pelanggan',
              ),
              keyboardType: TextInputType.number,
            ),
            if (item.nameController.text.isNotEmpty &&
                (int.tryParse(item.qtyController.text) ?? 0) > 0 &&
                (double.tryParse(item.priceController.text) ?? 0) > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Subtotal: ${FormatHelpers.rupiah(
                    (int.tryParse(item.qtyController.text) ?? 0) *
                        (double.tryParse(item.priceController.text) ?? 0),
                  )}',
                  style: AppTheme.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.infoColorTheme(context),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection() {
    return Column(
      children: [
        TextFormField(
          controller: _descriptionController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Deskripsi (opsional)',
            prefixIcon: Icon(Icons.description_outlined),
            hintText: 'Deskripsi konsinyasi',
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tanggal', style: AppTheme.heading3),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _pickDate(false),
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Tanggal Titip',
              prefixIcon: Icon(Icons.calendar_today_rounded),
            ),
            child: Text(FormatHelpers.displayDate(_consignmentDate)),
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _pickDate(true),
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Jatuh Tempo (opsional)',
              prefixIcon: const Icon(Icons.event_outlined),
              suffixIcon: _dueDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => setState(() => _dueDate = null),
                    )
                  : null,
            ),
            child: Text(
              _dueDate != null ? FormatHelpers.displayDate(_dueDate!) : '-',
              style: TextStyle(
                color: _dueDate != null ? null : Colors.grey.shade500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.calculate_outlined,
                    size: 20, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Total Nilai Titipan',
                      style: AppTheme.labelSmall),
                ),
                Text(
                  FormatHelpers.rupiah(_calculateTotal()),
                  style: AppTheme.amountMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
