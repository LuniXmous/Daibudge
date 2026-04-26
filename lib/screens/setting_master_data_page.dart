import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../db/database_helper.dart';
import '../theme/theme_controller.dart';

class SettingMasterDataPage extends StatefulWidget {
  final String title;
  final String tableType;

  const SettingMasterDataPage({
    super.key,
    required this.title,
    required this.tableType,
  });

  @override
  State<SettingMasterDataPage> createState() => _SettingMasterDataPageState();
}

class _SettingMasterDataPageState extends State<SettingMasterDataPage> {
  List<Map<String, dynamic>> items = [];

  final List<Color> walletColorOptions = [
    Colors.pink.shade700,
    Colors.cyan.shade700,
    Colors.deepPurple.shade600,
    Colors.orange.shade700,
    Colors.green.shade700,
    Colors.blue.shade700,
    Colors.teal.shade700,
    Colors.red.shade700,
    Colors.indigo.shade700,
    Colors.amber.shade700,
    Colors.brown.shade700,
    Colors.blueGrey.shade700,
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    List<Map<String, dynamic>> result = [];

    if (widget.tableType == 'wallet') {
      result = await DatabaseHelper.instance.getWalletMethods();
    } else {
      result = await DatabaseHelper.instance.getIncomeSources();
    }

    setState(() {
      items = result;
    });
  }

  Future<void> showColorPickerDialog({
    required Color initialColor,
    required ValueChanged<Color> onColorChanged,
  }) async {
    Color pickedColor = initialColor;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Warna'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickedColor,
            onColorChanged: (color) {
              pickedColor = color;
            },
            enableAlpha: false,
            displayThumbColor: true,
            portraitOnly: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              onColorChanged(pickedColor);
              Navigator.pop(context);
            },
            child: const Text('Pilih'),
          ),
        ],
      ),
    );
  }

  Future<void> showFormDialog({Map<String, dynamic>? item}) async {
    final controller = TextEditingController(text: item?['name'] ?? '');
    final isEdit = item != null;
    int selectedColor =
        item?['color'] as int? ?? Colors.blueGrey.shade400.value;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Data' : 'Tambah Data'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Nama',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (widget.tableType == 'wallet') ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Warna Kantong',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: walletColorOptions.map((color) {
                          final isSelected = selectedColor == color.value;

                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedColor = color.value;
                              });
                            },
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 18,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await showColorPickerDialog(
                              initialColor: Color(selectedColor),
                              onColorChanged: (color) {
                                setModalState(() {
                                  selectedColor = color.value;
                                });
                              },
                            );
                          },
                          icon: const Icon(Icons.palette_outlined),
                          label: const Text('Pilih warna bebas'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'Preview:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: Color(selectedColor),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = controller.text.trim();
                    if (name.isEmpty) return;

                    if (widget.tableType == 'wallet') {
                      if (isEdit) {
                        await DatabaseHelper.instance.updateWalletMethod(
                          item['id'] as int,
                          name,
                          selectedColor,
                        );
                      } else {
                        await DatabaseHelper.instance.insertWalletMethod(
                          name,
                          selectedColor,
                        );
                      }
                    } else {
                      if (isEdit) {
                        await DatabaseHelper.instance.updateIncomeSource(
                          item['id'] as int,
                          name,
                        );
                      } else {
                        await DatabaseHelper.instance.insertIncomeSource(name);
                      }
                    }

                    if (!mounted) return;
                    Navigator.pop(dialogContext);
                    await loadData();
                  },
                  child: Text(isEdit ? 'Update' : 'Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> deleteItem(int id) async {
    if (widget.tableType == 'wallet') {
      await DatabaseHelper.instance.deleteWalletMethod(id);
    } else {
      await DatabaseHelper.instance.deleteIncomeSource(id);
    }
    await loadData();
  }

  Future<void> showDeleteDialog(int id) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Data'),
        content: const Text('Yakin mau hapus data ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await deleteItem(id);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWallet = widget.tableType == 'wallet';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: items.isEmpty
          ? const Center(child: Text('Belum ada data'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final itemColor = isWallet
                    ? Color(item['color'] as int? ?? Colors.blueGrey.value)
                    : null;

                return Card(
                  child: ListTile(
                    leading: isWallet
                        ? CircleAvatar(
                            backgroundColor: itemColor,
                            radius: 12,
                          )
                        : null,
                    title: Text(item['name'] as String),
                    onTap: () => showFormDialog(item: item),
                    onLongPress: () => showDeleteDialog(item['id'] as int),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => showFormDialog(item: item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () =>
                              showDeleteDialog(item['id'] as int),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showFormDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}