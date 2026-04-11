import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nexus_cts/view/device_properties/device_properties_page.dart';
import 'package:nexus_cts/view/home/home_page.dart';
import 'package:nexus_cts/view/run/run_suite_page.dart';
import 'package:nexus_cts/view/settings/settings_page.dart';
import 'package:nexus_cts/view/verifier/verifier_results_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blueGrey),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SvgPicture.asset(
                    'assets/main_logo.svg',
                    height: 52,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Nexus CTS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Google Suite Centralizer',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomePage()),
                (_) => false,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.rocket_launch),
            title: const Text('Executar Suíte'),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const RunSuitePage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.perm_device_information),
            title: const Text('Device Properties'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DevicePropertiesPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.verified_user),
            title: const Text('Verifier Results'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const VerifierResultsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configurações'),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
            },
          ),
          const Spacer(),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'nexus_cts v0.3.1',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
