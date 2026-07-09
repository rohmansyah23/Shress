import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/database.dart';
import '../../data/local/models/category_model.dart';
import '../../data/local/models/business_model.dart';

class CategoryManagementScreen extends StatefulWidget {
  final BusinessModel business;

  const CategoryManagementScreen({super.key, required this.business});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  late List<CategoryModel> _categories;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _categories = LocalDatabase.instance.getCategoriesByBusiness(widget.business.businessId);
    setState(() {});
  }

  void _showAdd() {
    final nameCtrl = TextEditingController();
    var type = 'expense';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Kategori'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: type,
              items: const [
                DropdownMenuItem(value: 'income', child: Text('Income')),
                DropdownMenuItem(value: 'expense', child: Text('Expense')),
              ],
              onChanged: (v) => type = v ?? 'expense',
              decoration: const InputDecoration(labelText: 'Tipe'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              // generate new categoryId
              final existing = LocalDatabase.instance.getCategoriesByBusiness(widget.business.businessId);
              final nextId = (existing.map((e) => e.categoryId).fold<int>(0, (p, n) => n > p ? n : p)) + 1;
              final newCat = CategoryModel(categoryId: nextId, businessId: widget.business.businessId, name: name, type: type);
              await LocalDatabase.instance.saveCategory(newCat);
              if (!mounted) return;
              Navigator.of(context).pop();
              _load();
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
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: type,
              items: const [
                DropdownMenuItem(value: 'income', child: Text('Income')),
                DropdownMenuItem(value: 'expense', child: Text('Expense')),
              ],
              onChanged: (v) => type = v ?? 'expense',
              decoration: const InputDecoration(labelText: 'Tipe'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final updated = CategoryModel(categoryId: c.categoryId, businessId: c.businessId, name: name, type: type, createdAt: c.createdAt, lastSyncedAt: c.lastSyncedAt);
              await LocalDatabase.instance.saveCategory(updated);
              if (!mounted) return;
              Navigator.of(context).pop();
              _load();
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
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              await LocalDatabase.instance.deleteCategory(c.categoryId);
              if (!mounted) return;
              Navigator.of(context).pop();
              _load();
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
      body: _categories.isEmpty
          ? Center(
              child: Text('Belum ada kategori', style: AppTheme.heading3.copyWith(color: Colors.grey)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final c = _categories[index];
                return Card(
                  child: ListTile(
                    title: Text(c.name),
                    subtitle: Text(c.type),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded),
                          onPressed: () => _showEdit(c),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_rounded),
                          onPressed: () => _confirmDelete(c),
                        ),
                    ]),
                  ),
                );
              },
            ),
    );
  }
}
