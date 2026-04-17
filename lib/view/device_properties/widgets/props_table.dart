import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PropsTable extends StatefulWidget {
  final Map<String, String> properties;
  final String title;
  final IconData icon;
  final bool initiallyExpanded;

  const PropsTable({
    super.key,
    required this.properties,
    this.title = '',
    this.icon = Icons.list,
    this.initiallyExpanded = true,
  });

  @override
  State<PropsTable> createState() => _PropsTableState();
}

class _PropsTableState extends State<PropsTable>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _animController;
  late Animation<double> _heightFactor;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _animController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
      value: _expanded ? 1.0 : 0.0,
    );
    _heightFactor = _animController.drive(CurveTween(curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.properties.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title.isNotEmpty)
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                children: [
                  Icon(widget.icon, size: 16, color: Colors.blueAccent),
                  const SizedBox(width: 6),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${entries.length} itens',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0.0 : -0.25,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.expand_more,
                      size: 18,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ),
        AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: _heightFactor.value,
                child: child,
              ),
            );
          },
          child: Container(
            constraints: const BoxConstraints(maxHeight: 500),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: entries.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Colors.grey.withValues(alpha: 0.1),
                ),
                itemBuilder: (context, index) {
                  final e = entries[index];
                  return _PropRow(propKey: e.key, propValue: e.value);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PropRow extends StatelessWidget {
  final String propKey;
  final String propValue;

  const _PropRow({required this.propKey, required this.propValue});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: '$propKey=$propValue'));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copiado: $propKey'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 360,
              child: Text(
                propKey,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'monospace',
                  color: Colors.blueGrey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                propValue.isEmpty ? '(empty)' : propValue,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'monospace',
                  color: propValue.isEmpty ? Colors.grey[400] : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
