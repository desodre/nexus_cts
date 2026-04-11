import 'package:flutter/material.dart';
import 'package:nexus_cts/view/home/widgets/device_list_section.dart';
import 'package:nexus_cts/view/home/widgets/its_results_section.dart';
import 'package:nexus_cts/view/home/widgets/results_section.dart';
import 'package:nexus_cts/view/widgets/app_drawer.dart';
import 'package:nexus_cts/viewmodels/home_viewmodel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _vm = HomeViewModel();

  @override
  void initState() {
    super.initState();
    _vm.init();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Nexus CTS Home Page', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500))),
          drawer: const AppDrawer(),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DeviceListSection(
                  loading: _vm.loadingDevices,
                  error: _vm.devicesError,
                  devices: _vm.devices,
                  onRefresh: _vm.fetchDevices,
                ),
                const Divider(height: 32),
                Expanded(
                  child: ListView(
                    children: [
                      ResultsSection(
                        loading: _vm.loadingResults,
                        noSuiteConfigured: _vm.noSuiteConfigured,
                        results: _vm.results,
                        groupedResults: _vm.groupedResults,
                        orderedGroupKeys: _vm.orderedGroupKeys,
                        onRefresh: _vm.fetchResults,
                      ),
                      const Divider(height: 32),
                      ItsResultsSection(
                        itsResults: _vm.itsResults,
                        loadingItsResults: _vm.loadingItsResults,
                        loadingResults: _vm.loadingResults,
                        onRefresh: _vm.fetchItsResults,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
