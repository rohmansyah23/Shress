import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_handler.dart';
import '../../core/widgets/error_widgets.dart';
import '../../core/widgets/skeleton_widgets.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
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
        title: const Text('Tambah Kategori'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: type,
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
                await Supabase.instance.client.from('categories').insert({
                  'business_id': widget.business.businessId,
                  'name': name,
                  'type': type,
                });
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
        title: const Text('Edit Kategori'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: type,
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
                await Supabase.instance.client
                    .from('categories')
                    .update({'name': name, 'type': type})
                    .eq('id', c.categoryId);
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
        title: const Text('Hapus Kategori'),
        content: Text('Hapus kategori "${c.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await Supabase.instance.client
                    .from('categories')
                    .delete()
                    .eq('id', c.categoryId);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Kategori')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAdd,
        child: const Icon(Icons.add_rounded),
      ),
      body: _isLoading
          ? const Center(
              child: ShimmerWidget(width: 48, height: 48, borderRadius: 24),
            )
          : _categories.isEmpty
              ? Center(
                  child: Text('Belum ada kategori',
                      style:
                          AppTheme.heading3.copyWith(color: Colors.grey)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _categories.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final c = _categories[index];
                    return Card(
                      child: ListTile(
                        title: Text(c.name),
                        subtitle: Text(
                          c.type == AppConstants.typeIncome ? 'Pemasukan' : 'Pengeluaran',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded),
                              onPressed: () => _showEdit(c),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_rounded),
                              onPressed: () => _confirmDelete(c),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
