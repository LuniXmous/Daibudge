import 'package:flutter/material.dart';
import 'setting_master_data_page.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('Metode Transaksi / Kantong'),
              subtitle: const Text('Tambah, ubah, hapus metode transaksi'),
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
        ],
      ),
    );
  }
}