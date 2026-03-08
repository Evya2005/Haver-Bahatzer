import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tag_model.dart';
import '../../providers/tag_provider.dart';
import '../../widgets/common/error_snackbar.dart';

/// Predefined (bgColor, textColor) pairs for tag color selection.
const _colorPairs = [
  (bg: 0xFFFFCDD2, text: 0xFFC62828), // red
  (bg: 0xFFE3F2FD, text: 0xFF1565C0), // blue
  (bg: 0xFFFFF9C4, text: 0xFF7B4500), // yellow
  (bg: 0xFFE8F5E9, text: 0xFF1B5E20), // green
  (bg: 0xFFF3E5F5, text: 0xFF6A1B9A), // purple
  (bg: 0xFFFFF3E0, text: 0xFFE65100), // orange
  (bg: 0xFFE0F2F1, text: 0xFF004D40), // teal
  (bg: 0xFFFCE4EC, text: 0xFF880E4F), // pink
];

class TagSettingsScreen extends StatelessWidget {
  const TagSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TagProvider>();
    final tags = provider.tags;

    return Scaffold(
      appBar: AppBar(title: const Text('הגדרות תגיות')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTagDialog(context, null),
        child: const Icon(Icons.add),
      ),
      body: tags.isEmpty
          ? const Center(child: Text('אין תגיות. לחץ + כדי להוסיף.'))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: tags.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) => _TagTile(tag: tags[i]),
            ),
    );
  }

  Future<void> _showTagDialog(BuildContext context, CustomTag? existing) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _TagDialog(existing: existing),
    );
  }
}

class _TagTile extends StatelessWidget {
  final CustomTag tag;

  const _TagTile({required this.tag});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Color(tag.bgColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'א',
            style: TextStyle(
              color: Color(tag.textColor),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      title: Text(tag.label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (ctx) => _TagDialog(existing: tag),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('מחיקת תגית'),
        content: Text('למחוק את התגית "${tag.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('מחק'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final provider = context.read<TagProvider>();
    await provider.deleteTag(tag.id);

    if (!context.mounted) return;
    if (provider.errorMessage != null) {
      showErrorSnackbar(context, provider.errorMessage!);
      provider.clearError();
    }
  }
}

class _TagDialog extends StatefulWidget {
  final CustomTag? existing;

  const _TagDialog({this.existing});

  @override
  State<_TagDialog> createState() => _TagDialogState();
}

class _TagDialogState extends State<_TagDialog> {
  late final TextEditingController _labelController;
  late int _selectedBg;
  late int _selectedText;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _labelController =
        TextEditingController(text: widget.existing?.label ?? '');
    _labelController.addListener(() => setState(() {}));
    final pair = widget.existing != null
        ? _findMatchingPair(widget.existing!.bgColor, widget.existing!.textColor)
        : _colorPairs[0];
    _selectedBg = pair.bg;
    _selectedText = pair.text;
  }

  ({int bg, int text}) _findMatchingPair(int bg, int text) {
    for (final p in _colorPairs) {
      if (p.bg == bg && p.text == text) return p;
    }
    return _colorPairs[0];
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final label = _labelController.text.trim();
    if (label.isEmpty) return;

    setState(() => _saving = true);
    final provider = context.read<TagProvider>();

    if (widget.existing == null) {
      await provider.addTag(label, _selectedBg, _selectedText);
    } else {
      await provider.updateTag(widget.existing!.copyWith(
        label: label,
        bgColor: _selectedBg,
        textColor: _selectedText,
      ));
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (provider.errorMessage != null) {
      showErrorSnackbar(context, provider.errorMessage!);
      provider.clearError();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return AlertDialog(
      title: Text(isEdit ? 'עריכת תגית' : 'תגית חדשה'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _labelController,
            autofocus: true,
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(labelText: 'שם תגית'),
          ),
          const SizedBox(height: 16),
          const Text('צבע:', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _colorPairs.map((pair) {
              final isSelected =
                  pair.bg == _selectedBg && pair.text == _selectedText;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedBg = pair.bg;
                  _selectedText = pair.text;
                }),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(pair.bg),
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: Colors.black87, width: 2.5)
                        : null,
                  ),
                  child: isSelected
                      ? Icon(Icons.check, size: 20, color: Color(pair.text))
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Preview
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color(_selectedBg),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _labelController.text.isEmpty
                  ? 'תצוגה מקדימה'
                  : _labelController.text,
              style: TextStyle(
                color: Color(_selectedText),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ביטול'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEdit ? 'שמור' : 'הוסף'),
        ),
      ],
    );
  }
}
