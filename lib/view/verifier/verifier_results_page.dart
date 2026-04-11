import 'package:flutter/material.dart';

import 'package:nexus_cts/models/verifier_result.dart';
import 'package:nexus_cts/view/verifier/widgets/execution_card.dart';
import 'package:nexus_cts/view/verifier/widgets/execution_detail.dart';
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
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_vm.executions.isEmpty) {
      return _buildEmptyState();
    }

    if (_vm.selectedExecution != null) {
      return ExecutionDetail(vm: _vm, searchController: _searchController);
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

  Widget _buildExecutionList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _vm.executions.length,
      itemBuilder: (context, index) {
        final exec = _vm.executions[index];
        return ExecutionCard(
          exec: exec,
          onTap: () {
            _searchController.clear();
            _vm.selectExecution(exec);
          },
          onDelete: () => _confirmDelete(exec),
        );
      },
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
