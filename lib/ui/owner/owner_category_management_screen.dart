import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';
import '../../core/utils/error_handler.dart';
import '../../core/widgets/error_widgets.dart';
import '../../data/local/models/category_model.dart';
import '../../data/local/models/business_model.dart';
import '../../data/remote/supabase_service.dart';

class OwnerCategoryManagementScreen extends StatefulWidget {
  final List<BusinessModel> businesses;

  const OwnerCategoryManagementScreen({super.key, required this.businesses});

  @override
  State<OwnerCategoryManagementScreen> createState() =>
      _OwnerCategoryManagementScreenState();
}

class _OwnerCategoryManagementScreenState extends State<OwnerCategoryManagementScreen> {
  BusinessModel? _selectedBusinessFilter;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  Map<int, List<CategoryModel>> _businessCategories = {};
  bool _isLoading = true;

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
      final results = await Future.wait(
        widget.businesses.map(
          (b) => SupabaseService.instance.getCategoriesByBusiness(b.businessId),
        ),
      );
      final map = <int, List<CategoryModel>>{};
      for (int i = 0; i < widget.businesses.length; i++) {
        map[widget.businesses[i].businessId] = results[i];
      }
      if (mounted) {
        setState(() {
          _businessCategories = map;
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

  void _showAdd() async {
    BusinessModel? targetBusiness;
    if (_selectedBusinessFilter != null) {
      targetBusiness = _selectedBusinessFilter;
    } else {
      targetBusiness = await showDialog<BusinessModel>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
          ),
          title: const Text('Pilih Bisnis'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.businesses.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final b = widget.businesses[index];
                return ListTile(
                  leading: const Icon(Icons.store_rounded),
                  title: Text(b.name),
                  onTap: () => Navigator.pop(ctx, b),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
          ],
        ),
      );
    }

    if (targetBusiness == null) return;

    if (!mounted) return;
    _showAddDialogForBusiness(targetBusiness);
  }

  void _showAddDialogForBusiness(BusinessModel business) {
    final nameCtrl = TextEditingController();
    var type = AppConstants.typeExpense;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.radiusMedium)),
        title: Text('Tambah Kategori (${business.name})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Kategori'),
            ),
            const SizedBox(height: AppSpacing.s12),
            DropdownButtonFormField<String>(
              initialValue: type,
              borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
              dropdownColor: AppTheme.surfaceColorTheme(context),
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
                  businessId: business.businessId,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.radiusMedium)),
        title: const Text('Edit Kategori'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Kategori'),
            ),
            const SizedBox(height: AppSpacing.s12),
            DropdownButtonFormField<String>(
              initialValue: type,
              borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
              dropdownColor: AppTheme.surfaceColorTheme(context),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.radiusSmall)),
        title: const Text('Hapus Kategori'),
        content: Text('Hapus kategori "${c.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.lossColorTheme(context),
              foregroundColor: AppTheme.onDangerColorTheme(context),
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
    final filteredCategories = <({CategoryModel category, BusinessModel business})>[];

    for (final business in widget.businesses) {
      if (_selectedBusinessFilter != null &&
          _selectedBusinessFilter!.businessId != business.businessId) {
        continue;
      }
      final categories = _businessCategories[business.businessId] ?? [];
      for (final cat in categories) {
        final matchSearch = _searchQuery.isEmpty ||
            cat.name.toLowerCase().contains(_searchQuery) ||
            (cat.type == AppConstants.typeIncome ? 'pemasukan' : 'pengeluaran')
                .contains(_searchQuery);
        if (matchSearch) {
          filteredCategories.add((category: cat, business: business));
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Kategori')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAdd,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.s16, 0, AppSpacing.s16, AppSpacing.s16),
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
                contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
                filled: true,
                fillColor: AppTheme.surfaceColorTheme(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
                  borderSide: BorderSide(color: AppTheme.outlineColorTheme(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
                  borderSide: BorderSide(color: AppTheme.outlineColorTheme(context).withValues(alpha: 0.5)),
                ),
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : () {
                    if (filteredCategories.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.category_rounded,
                              size: 64,
                              color: AppTheme.onSurfaceVariantColorTheme(context).withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: AppSpacing.s16),
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
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                        itemCount: filteredCategories.length,
                        itemBuilder: (context, index) {
                          final item = filteredCategories[index];
                          final c = item.category;
                          final b = item.business;
                          final isIncome = c.type == AppConstants.typeIncome;
                          return Card(
                            margin: const EdgeInsets.only(bottom: AppSpacing.s12),
                            clipBehavior: Clip.antiAlias,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(AppSpacing.s16, AppSpacing.s12, AppSpacing.s8, AppSpacing.s12),
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
                                  const SizedBox(width: AppSpacing.s12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(c.name, style: AppTheme.heading3),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              b.name,
                                              style: AppTheme.caption.copyWith(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.onSurfaceVariantColorTheme(context),
                                              ),
                                            ),
                                            const Text(' • '),
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
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: Icon(
                                      Icons.more_vert_rounded,
                                      color: AppTheme.onSurfaceVariantColorTheme(context),
                                      size: 20,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
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
                                              color: AppTheme.onSurfaceColorTheme(context)),
                                          title: Text('Edit Kategori',
                                              style: TextStyle(
                                                  color: AppTheme.onSurfaceColorTheme(context))),
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

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
      child: Row(
        children: [
          _buildChip(
            label: 'Semua Bisnis',
            isSelected: _selectedBusinessFilter == null,
            onTap: () => setState(() => _selectedBusinessFilter = null),
          ),
          ...widget.businesses.map((business) {
            final isSelected = _selectedBusinessFilter?.businessId == business.businessId;
            return Padding(
              padding: const EdgeInsets.only(left: AppSpacing.s8),
              child: _buildChip(
                label: business.name,
                isSelected: isSelected,
                onTap: () => setState(() => _selectedBusinessFilter = business),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final primaryColor = AppTheme.primaryColorTheme(context);
    final surfaceContainer = AppTheme.surfaceContainerColorTheme(context);
    final onSurface = AppTheme.onSurfaceColorTheme(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.radiusPill),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : AppTheme.outlineColorTheme(context).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
