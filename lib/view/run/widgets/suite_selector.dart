import 'package:flutter/material.dart';
import 'package:nexus_cts/models/suite_entry.dart';
import 'package:nexus_cts/view/widgets/suite_icon_helper.dart';

class SuiteSelector extends StatelessWidget {
  final List<SuiteEntry> suites;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  const SuiteSelector({
    super.key,
    required this.suites,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return RadioGroup<int>(
      groupValue: selectedIndex ?? -1,
      onChanged: (v) {
        if (v != null && v != -1) onSelect(v);
      },
      child: Column(
        children: List.generate(suites.length, (i) {
          final s = suites[i];
          final (_, Color color) = suiteIconData(s.type);
          return ListTile(
            leading: Radio<int>(value: i),
            title: Text('${s.name} (${s.type})'),
            subtitle: Text(s.path, overflow: TextOverflow.ellipsis),
            trailing: Icon(suiteIconData(s.type).$1, color: color),
            onTap: () => onSelect(i),
          );
        }),
      ),
    );
  }
}
