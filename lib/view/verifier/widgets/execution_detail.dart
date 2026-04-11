import 'package:flutter/material.dart';
import 'package:nexus_cts/models/verifier_result.dart';
import 'package:nexus_cts/view/verifier/widgets/camera_its_panel.dart';
import 'package:nexus_cts/view/verifier/widgets/its_xml_scenes_panel.dart';
import 'package:nexus_cts/view/verifier/widgets/module_section.dart';
import 'package:nexus_cts/viewmodels/verifier_results_viewmodel.dart';

class ExecutionDetail extends StatelessWidget {
  final VerifierResultsViewModel vm;
  final TextEditingController searchController;

  const ExecutionDetail({
    super.key,
    required this.vm,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    final exec = vm.selectedExecution!;

    return Column(
      children: [
        _buildHeader(context, exec),
        if (vm.hasItsScenes) ItsXmlScenesPanel(scenes: vm.itsXmlScenes),
        if (vm.cameraItsScenes.isNotEmpty)
          CameraItsPanel(
            scenes: vm.cameraItsScenes,
            logPath: vm.cameraItsLogPath,
          ),
        Expanded(child: _buildModuleTable()),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, VerifierExecution exec) {
    return Container(
      width: double.infinity,
      color: Colors.blueGrey[50],
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: vm.clearSelection,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exec.suitePlan ?? 'CTS Verifier',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (exec.buildFingerprint != null)
                      Text(
                        exec.buildFingerprint!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              FilterChip(
                label: const Text('Apenas falhas'),
                selected: vm.showOnlyFailed,
                onSelected: (_) => vm.toggleFailedFilter(),
              ),
              const SizedBox(width: 8),
              if (vm.hasCameraItsFailures)
                ElevatedButton.icon(
                  onPressed: vm.pickCameraItsLogs,
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Logs CameraITS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Pesquisar módulos ou testes...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: vm.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        searchController.clear;
                        vm.setSearchQuery('');
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: vm.setSearchQuery,
          ),
        ],
      ),
    );
  }

  Widget _buildModuleTable() {
    final mods = vm.modules;

    if (mods.isEmpty) {
      return Center(
        child: Text(
          vm.showOnlyFailed
              ? 'Nenhum módulo com falha'
              : vm.searchQuery.isNotEmpty
              ? 'Nenhum resultado para "${vm.searchQuery}"'
              : 'Nenhum módulo encontrado',
          style: TextStyle(color: Colors.grey[500]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: mods.length,
      itemBuilder: (context, index) {
        final mod = mods[index];
        final tcs = vm.testCasesForModule(mod.id!);
        return ModuleSection(module: mod, testCases: tcs);
      },
    );
  }
}
