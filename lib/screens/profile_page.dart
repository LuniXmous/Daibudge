import 'package:flutter/material.dart';
import '../theme/theme_controller.dart';
import '../services/google_sheets_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'setting_master_data_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
  
}

class _ProfilePageState extends State<ProfilePage> {
  final googleService = GoogleSheetsService();
  final ImagePicker picker = ImagePicker();

  static const String nameKey = 'profile_custom_name';
  static const String photoKey = 'profile_custom_photo_path';
  
  GoogleSignInAccount? user;
  String? customName;
  String? customPhotoUrl;
  bool isLoading = false;

 @override
  void initState() {
    super.initState();
    initUser();
  }

  Future<void> initUser() async {
    await googleService.tryAutoLogin();

    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString(nameKey);
    final savedPhotoPath = prefs.getString(photoKey);

    if (!mounted) return;

    setState(() {
      user = googleService.currentUser;
      customName = savedName ?? user?.displayName;
      customPhotoUrl = savedPhotoPath ?? user?.photoUrl;
    });
  }

  Widget build(BuildContext context) {
    final isDark = isDarkMode.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
      ),
      body: user == null ? Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.login),
            label: const Text('Login Google'),
            onPressed: () async {
              final loggedUser = await googleService.signIn();

              if (loggedUser != null) {
                setState(() {
                  user = loggedUser;
                  customName = loggedUser.displayName;
                  customPhotoUrl = loggedUser.photoUrl;
                });
              }
            },
          ),
        )
      : SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final pickedFile = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 75,
                          );

                          if (pickedFile == null) return;

                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString(photoKey, pickedFile.path);

                          setState(() {
                            customPhotoUrl = pickedFile.path;
                          });
                        },
                        child: CircleAvatar(
                          radius: 42,
                          backgroundImage: customPhotoUrl != null
                              ? customPhotoUrl!.startsWith('http')
                                  ? NetworkImage(customPhotoUrl!)
                                  : FileImage(File(customPhotoUrl!)) as ImageProvider
                              : null,
                          child: customPhotoUrl == null
                              ? const Icon(Icons.person, size: 42)
                              : null,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            customName ?? 'User',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () async {
                              final controller = TextEditingController(
                                text: customName ?? '',
                              );

                              final result = await showDialog<String>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Edit Nama Profil'),
                                  content: TextField(
                                    controller: controller,
                                    decoration: const InputDecoration(
                                      hintText: 'Masukkan nama',
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Batal'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(
                                        context,
                                        controller.text,
                                      ),
                                      child: const Text('Simpan'),
                                    ),
                                  ],
                                ),
                              );

                              if (result != null && result.trim().isNotEmpty) {
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setString(nameKey, result.trim());

                                setState(() {
                                  customName = result.trim();
                                });
                              }
                            },
                          ),
                        ],
                      ), 

                      Text(
                        user!.email,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.table_chart_outlined),
                title: const Text('Spreadsheet'),
                subtitle: const Text('Kelola dan lihat data Google Sheets'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder: (context) {
                        final controller = TextEditingController();

                        return AlertDialog(
                          title: const Text('Kelola Spreadsheet'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.copy),
                                label: const Text('Buat dari Template'),
                                onPressed: () async {
                                  Navigator.pop(context);

                                  final id = await googleService.createSpreadsheetFromTemplate();

                                  if (id != null) {
                                    await googleService.saveActiveSpreadsheetId(id);
                                  }
                                },
                              ),

                              const SizedBox(height: 12),

                              ElevatedButton.icon(
                                icon: const Icon(Icons.link),
                                label: const Text('Import Spreadsheet'),
                                onPressed: () async {
                                  final result = await showDialog<String>(
                                    context: context,
                                    builder: (context) {
                                      final inputController = TextEditingController();

                                      return AlertDialog(
                                        title: const Text('Import Spreadsheet'),
                                        content: TextField(
                                          controller: inputController,
                                          decoration: const InputDecoration(
                                            hintText: 'Paste link atau ID',
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Batal'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(context, inputController.text),
                                            child: const Text('Import'),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (result != null && result.trim().isNotEmpty) {
                                    await googleService.importSpreadsheet(result);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Spreadsheet berhasil dihubungkan')),
                                    );
                                  }

                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                onTap: () async {
                  final spreadsheetId = await googleService.getActiveSpreadsheetId();

                  print('OPENING SPREADSHEET: $spreadsheetId');

                  if (spreadsheetId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Belum ada spreadsheet aktif')),
                    );
                    return;
                  }

                  final url = Uri.parse(
                    googleService.getSpreadsheetUrl(spreadsheetId),
                  );

                  await launchUrl(
                    url,
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
            ),

            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: Divider(
                    thickness: 1,
                    color: Colors.grey.shade400,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    'Pengaturan Data',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    thickness: 1,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
            
            Card(
              child: ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('Metode Transaksi / Kantong'),
                subtitle: const Text('Tambah, ubah, hapus kantong'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingMasterDataPage(
                        title: 'Metode Transaksi / Kantong',
                        tableType: 'wallet',
                      ),
                    ),
                  );
                },
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.attach_money_outlined),
                title: const Text('Sumber Pemasukan'),
                subtitle: const Text('Tambah, ubah, hapus sumber pemasukan'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingMasterDataPage(
                        title: 'Sumber Pemasukan',
                        tableType: 'income',
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Divider(
                    thickness: 1,
                    color: Colors.grey.shade400,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  child: Text(
                    'Tampilan',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    thickness: 1,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Dark Mode'),
                trailing: Switch(
                  value: isDarkMode.value,
                  onChanged: (val) {
                    isDarkMode.value = val;
                    setState(() {});
                  },
                ),
              ),
            ),

            const SizedBox(height: 19),
              Center(
                child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  onPressed: () async {
                    await googleService.disconnect();

                    setState(() {
                      user = null;
                    });
                  },
                  child: const Text('Logout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}