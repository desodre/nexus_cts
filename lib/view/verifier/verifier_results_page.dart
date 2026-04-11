import 'package:flutter/material.dart';

import 'package:nexus_cts/models/verifier_result.dart';
import 'package:nexus_cts/view/widgets/app_drawer.dart';
import 'package:nexus_cts/viewmodels/verifier_results_viewmodel.dart';

class VerifierResultsPage extends StatefulWidget {
  const VerifierResultsPage({super.key});

  @override
  State<VerifierResultsPage> createState() => _VerifierResultsPageState();
}

class _VerifierResultsPageState extends State<VerifierResultsPage> {
  final _vm = VerifierResultsViewModel();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm.init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('CTS Verifier Results'),
            actions: [
              if (_vm.importing)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.file_open),
                  tooltip: 'Importar test_result.xml',
                  onPressed: _vm.pickAndImportXml,
                ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Atualizar',
                onPressed: _vm.loading ? null : _vm.fetchExecutions,
              ),
            ],
          ),
          drawer: const AppDrawer(),
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_vm.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_vm.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(_vm.error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: _vm.fetchExecutions,
                child: const Text('Tentar novamente')),
          ],
        ),
      );
    }

    if (_vm.executions.isEmpty) {
      return _buildEmptyState();
    }

    if (_vm.selectedExecution != null) {
      return _buildExecutionDetail();
    }

    return _buildExecutionList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nenhuma execução importada',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Importe um test_result.xml do CTS Verifier',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _vm.pickAndImportXml,
            icon: const Icon(Icons.file_open),
            label: const Text('Importar XML'),
          ),
        ],
      ),
    );
  }

  // ── Lista de execuções ──
  Widget _buildExecutionList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _vm.executions.length,
      itemBuilder: (context, index) {
        final exec = _vm.executions[index];
        return _buildExecutionCard(exec);
      },
    );
  }

  Widget _buildExecutionCard(VerifierExecution exec) {
    final passRate = exec.passRate;
    final color = passRate >= 95
        ? Colors.green
        : passRate >= 80
            ? Colors.orange
            : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          _searchController.clear();
          _vm.selectExecution(exec);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_user, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      exec.suitePlan ?? 'CTS Verifier',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (exec.suiteVersion != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(exec.suiteVersion!,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500])),
                    ),
                  Chip(
                    label: Text(
                      '${passRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: color.withValues(alpha: 0.1),
                    side: BorderSide(color: color.withValues(alpha: 0.3)),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: 'Remover',
                    onPressed: () => _confirmDelete(exec),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  _infoChip(Icons.check_circle, '${exec.passed}',
                      Colors.green),
                  _infoChip(Icons.cancel, '${exec.failed}', Colors.red),
                  _infoChip(Icons.remove_circle, '${exec.notExecuted}',
                      Colors.grey),
                  _infoChip(Icons.grid_view,
                      '${exec.modulesDone}/${exec.modulesTotal}', Colors.blue),
                ],
              ),
              const SizedBox(height: 8),
              if (exec.deviceSerial != null)
                Text('Serial: ${exec.deviceSerial}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[600])),
              if (exec.buildFingerprint != null)
                Text('Build: ${exec.buildFingerprint}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[600])),
              if (exec.startTime != null)
                Text('Início: ${exec.startTime}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 13, color: color)),
      ],
    );
  }

  // ── Detalhe da execução ──
  Widget _buildExecutionDetail() {
    final exec = _vm.selectedExecution!;

    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          color: Colors.blueGrey[50],
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _vm.clearSelection,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exec.suitePlan ?? 'CTS Verifier',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (exec.buildFingerprint != null)
                          Text(exec.buildFingerprint!,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  FilterChip(
                    label: const Text('Apenas falhas'),
                    selected: _vm.showOnlyFailed,
                    onSelected: (_) => _vm.toggleFailedFilter(),
                  ),
                  const SizedBox(width: 8),
                  if (_vm.hasCameraItsFailures)
                    ElevatedButton.icon(
                      onPressed: _vm.pickCameraItsLogs,
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
              // Search bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Pesquisar módulos ou testes...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _vm.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _vm.setSearchQuery('');
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: _vm.setSearchQuery,
              ),
            ],
          ),
        ),

        // ITS scenes from XML
        if (_vm.hasItsScenes) _buildItsXmlScenesPanel(),

        // Camera ITS failed scenes (from log folder)
        if (_vm.cameraItsScenes.isNotEmpty) _buildCameraItsPanel(),

        // Módulos
        Expanded(child: _buildModuleTable()),
      ],
    );
  }

  // ── ITS scenes panel (from XML) ──
  Widget _buildItsXmlScenesPanel() {
    return Container(
      width: double.infinity,
      color: Colors.blue[50],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.camera, color: Colors.blue, size: 18),
              const SizedBox(width: 8),
              const Text(
                'ITS Scenes (extraídas do XML)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              Text(
                '${_vm.itsXmlScenes.length} scene(s)',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _vm.itsXmlScenes.map((scene) {
              return Chip(
                label: Text(scene, style: const TextStyle(fontSize: 11)),
                backgroundColor: Colors.blue[50],
                side: BorderSide(color: Colors.blue[200]!),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Camera ITS logs panel ──
  Widget _buildCameraItsPanel() {
    return Container(
      width: double.infinity,
      color: Colors.orange[50],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.camera_alt, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Scenes com falha — ${_vm.cameraItsLogPath}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${_vm.cameraItsScenes.length} scene(s)',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _vm.cameraItsScenes.map((scene) {
              return Chip(
                label: Text(scene, style: const TextStyle(fontSize: 11)),
                backgroundColor: Colors.red[50],
                side: BorderSide(color: Colors.red[200]!),
                avatar: const Icon(Icons.warning_amber,
                    size: 14, color: Colors.red),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Lista de módulos (tabela) ──
  Widget _buildModuleTable() {
    final mods = _vm.modules;

    if (mods.isEmpty) {
      return Center(
        child: Text(
          _vm.showOnlyFailed
              ? 'Nenhum módulo com falha'
              : _vm.searchQuery.isNotEmpty
                  ? 'Nenhum resultado para "${_vm.searchQuery}"'
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
        final tcs = _vm.testCasesForModule(mod.id!);
        return _buildModuleSection(mod, tcs);
      },
    );
  }

  Widget _buildModuleSection(
      VerifierModule mod, List<VerifierTestCase> tcs) {
    final color = mod.failed > 0
        ? Colors.red
        : mod.done
            ? Colors.green
            : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Module header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            border: Border(
              left: BorderSide(color: color, width: 3),
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            children: [
              Icon(
                mod.failed > 0
                    ? Icons.error_outline
                    : Icons.check_circle_outline,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mod.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              _miniChip('P:${mod.passed}', Colors.green),
              const SizedBox(width: 6),
              _miniChip('F:${mod.failed}', Colors.red),
              const SizedBox(width: 6),
              _miniChip('T:${mod.totalTests}', Colors.grey),
            ],
          ),
        ),
        // Test case rows
        ...tcs.map((tc) => _buildTestRow(tc)),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _miniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildTestRow(VerifierTestCase tc) {
    final isPassed = tc.result == 'pass';
    final isFailed = tc.result == 'fail';
    final color = isPassed
        ? Colors.green
        : isFailed
            ? Colors.red
            : Colors.grey;
    final icon = isPassed
        ? Icons.check
        : isFailed
            ? Icons.close
            : Icons.remove;
    final hasDetails = tc.message != null || tc.stacktrace != null;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: hasDetails
          ? ExpansionTile(
              tilePadding: const EdgeInsets.only(left: 32, right: 12),
              leading: Icon(icon, color: color, size: 16),
              title: Text(tc.name, style: const TextStyle(fontSize: 13)),
              trailing: Text(
                tc.result.toUpperCase(),
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w500),
              ),
              children: [
                if (tc.message != null)
                  _detailBlock('Mensagem', tc.message!),
                if (tc.stacktrace != null)
                  _detailBlock('Stacktrace', tc.stacktrace!),
              ],
            )
          : ListTile(
              contentPadding:
                  const EdgeInsets.only(left: 32, right: 12),
              leading: Icon(icon, color: color, size: 16),
              title:
                  Text(tc.name, style: const TextStyle(fontSize: 13)),
              trailing: Text(
                tc.result.toUpperCase(),
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w500),
              ),
              dense: true,
            ),
    );
  }

  Widget _detailBlock(String title, String content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          SelectableText(
            content,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Colors.greenAccent,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(VerifierExecution exec) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover execução?'),
        content: Text(
          'Remover "${exec.suitePlan ?? 'CTS Verifier'}" '
          '(${exec.startTime ?? 'sem data'})?\n'
          'Todos os módulos e test cases serão removidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _vm.deleteExecution(exec.id!);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}
