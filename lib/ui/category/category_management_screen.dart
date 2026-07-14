import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/widgets/error_widgets.dart';
import '../../data/local/models/category_model.dart';
import '../../data/local/models/business_model.dart';
import '../../data/remote/supabase_service.dart';

class CategoryManagementScreen extends StatefulWidget {
  final BusinessModel business;

  const CategoryManagementScreen({super.key, required this.business});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  late List<CategoryModel> _categories;
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final categories = await SupabaseService.instance
          .getCategoriesByBusiness(widget.business.businessId);
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorSnackbar.show(context, ErrorHandler.classify(e));
      }
    }
  }

  void _showAdd() {
    final nameCtrl = TextEditingController();
    var type = AppConstants.typeExpense;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
        title: const Text('Tambah Kategori'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Kategori'),
            ),
            const SizedBox(height: AppTheme.s12),
            DropdownButtonFormField<String>(
              initialValue: type,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              dropdownColor: Theme.of(context).colorScheme.surface,
              items: const [
                DropdownMenuItem(value: 'income', child: Text('Pemasukan')),
                DropdownMenuItem(value: 'expense', child: Text('Pengeluaran')),
              ],
              onChanged: (v) => type = v ?? AppConstants.typeExpense,
              decoration: const InputDecoration(labelText: 'Tipe'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              try {
                await SupabaseService.instance.createCategory(
                  businessId: widget.business.businessId,
                  name: name,
                  type: type,
                );
                if (!mounted) return;
                Navigator.of(context).pop();
                _load();
              } catch (e) {
                if (!mounted) return;
                ErrorSnackbar.show(context, ErrorHandler.classify(e));
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _showEdit(CategoryModel c) {
    final nameCtrl = TextEditingController(text: c.name);
    var type = c.type;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
        title: const Text('Edit Kategori'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Kategori'),
            ),
            const SizedBox(height: AppTheme.s12),
            DropdownButtonFormField<String>(
              initialValue: type,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              dropdownColor: Theme.of(context).colorScheme.surface,
              items: const [
                DropdownMenuItem(value: 'income', child: Text('Pemasukan')),
                DropdownMenuItem(value: 'expense', child: Text('Pengeluaran')),
              ],
              onChanged: (v) => type = v ?? AppConstants.typeExpense,
              decoration: const InputDecoration(labelText: 'Tipe'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              try {
                await SupabaseService.instance.updateCategory(
                  categoryId: c.categoryId,
                  name: name,
                  type: type,
                );
                if (!mounted) return;
                Navigator.of(context).pop();
                _load();
              } catch (e) {
                if (!mounted) return;
                ErrorSnackbar.show(context, ErrorHandler.classify(e));
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(CategoryModel c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
        title: const Text('Hapus Kategori'),
        content: Text('Hapus kategori "${c.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              try {
                await SupabaseService.instance.deleteCategory(c.categoryId);
                if (!mounted) return;
                Navigator.of(context).pop();
                _load();
              } catch (e) {
                if (!mounted) return;
                ErrorSnackbar.show(context, ErrorHandler.classify(e));
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Kategori')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAdd,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari kategori...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : () {
                    final filtered = _categories.where((c) {
                      if (_searchQuery.isEmpty) return true;
                      return c.name.toLowerCase().contains(_searchQuery) ||
                          (c.type == AppConstants.typeIncome ? 'pemasukan' : 'pengeluaran')
                              .contains(_searchQuery);
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.category_rounded,
                              size: 64,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: AppTheme.s16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Tidak ada kategori ditemukan'
                                  : 'Belum ada kategori terdaftar',
                              style: AppTheme.caption.copyWith(fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final c = filtered[index];
                          final isIncome = c.type == AppConstants.typeIncome;
                          return Card(
                            margin: const EdgeInsets.only(bottom: AppTheme.s16),
                            clipBehavior: Clip.antiAlias,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: (isIncome ? AppTheme.profitColorTheme(context) : AppTheme.lossColorTheme(context))
                                        .withValues(alpha: 0.15),
                                    child: Icon(
                                      isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                      size: 18,
                                      color: isIncome ? AppTheme.profitColorTheme(context) : AppTheme.lossColorTheme(context),
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.s12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(c.name, style: AppTheme.heading3),
                                        const SizedBox(height: 2),
                                        Text(
                                          isIncome ? 'Pemasukan' : 'Pengeluaran',
                                          style: AppTheme.caption.copyWith(
                                            color: isIncome ? AppTheme.profitColorTheme(context) : AppTheme.lossColorTheme(context),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: Icon(
                                      Icons.more_vert_rounded,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      size: 20,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                    ),
                                    onSelected: (value) {
                                      switch (value) {
                                        case 'edit':
                                          _showEdit(c);
                                          break;
                                        case 'delete':
                                          _confirmDelete(c);
                                          break;
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem<String>(
                                        value: 'edit',
                                        child: ListTile(
                                          leading: Icon(Icons.edit_outlined,
                                              color: Theme.of(context).colorScheme.onSurface),
                                          title: Text('Edit Kategori',
                                              style: TextStyle(
                                                  color: Theme.of(context).colorScheme.onSurface)),
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                      const PopupMenuDivider(),
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        child: ListTile(
                                          leading: Icon(Icons.delete_outline_rounded,
                                              color: AppTheme.lossColorTheme(context)),
                                          title: Text('Hapus Kategori',
                                              style: TextStyle(
                                                  color: AppTheme.lossColorTheme(context))),
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }(),
          ),
        ],
      ),
    );
  }
}
