import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'form_provider.dart';
import 'model.dart';

// class DynamicFormScreen extends StatelessWidget {
//   const DynamicFormScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final p = context.watch<DynamicFormProvider>();
//     if (p.config == null) return const Center(child: CircularProgressIndicator());
//
//     return Scaffold(
//       appBar: AppBar(title: Text(p.config!.title)),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           for (final f in p.visibleFields)
//             Padding(padding: const EdgeInsets.only(bottom: 16), child: FieldRenderer(field: f)),
//           FilledButton(
//             onPressed: () {
//               final result = p.submit();
//               if (result == null) {
//                 ScaffoldMessenger.of(context)
//                     .showSnackBar(const SnackBar(content: Text('Please fix the highlighted fields')));
//                 return;
//               }
//               // Never display a password
//               final shown = Map<String, dynamic>.of(result);
//               for (final f in p.config!.fields.where((f) => f.type == 'password')) {
//                 if (shown.containsKey(f.id)) shown[f.id] = '********';
//               }
//               showDialog(
//                 context: context,
//                 builder: (_) => AlertDialog(
//                   title: const Text('Submitted values'),
//                   content: SingleChildScrollView(child: Text(const JsonEncoder.withIndent('  ').convert(shown))),
//                   actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
//                 ),
//               );
//             },
//             child: Text(p.config!.submitButton),
//           ),
//         ],
//       ),
//     );
//   }
// }

class DynamicFormScreen extends StatelessWidget {
  const DynamicFormScreen({super.key});

  bool _isFilled(dynamic v) =>
      v != null && v != false && !(v is String && v.trim().isEmpty) && !(v is List && v.isEmpty);


  @override
  Widget build(BuildContext context) {
    final p = context.watch<DynamicFormProvider>();
    if (p.config == null) return const Center(child: CircularProgressIndicator());

    final cs = Theme.of(context).colorScheme;
    final fields = p.visibleFields;
    final filled = fields.where((f) => _isFilled(p.values[f.id])).length;
    final progress = fields.isEmpty ? 0.0 : filled / fields.length;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        bottom: false,
        child: ListView(
          // big bottom padding so Submit clears the floating nav bar
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            // ---------- Header card ----------
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.assignment_ind_rounded, color: cs.onPrimary, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        p.config!.title,
                        style: TextStyle(color: cs.onPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$filled of ${fields.length} fields completed',
                    style: TextStyle(color: cs.onPrimary.withOpacity(0.9), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ---------- Fields ----------
            Card(
              elevation: 0,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    for (final f in fields)
                      Padding(
                        key: ValueKey('${f.id}-${p.resetCount}'), // keeps each field's state correct
                        padding: const EdgeInsets.only(bottom: 18),
                        child: FieldRenderer(field: f),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ---------- Submit ----------
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.send_rounded),
                label: Text(p.config!.submitButton, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                onPressed: () => _onSubmit(context, p),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSubmit(BuildContext context, DynamicFormProvider p) async {
    final result = p.submit();
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 100), // above the nav bar
          content: const Text('Please fix the highlighted fields'),
        ),
      );
      return;
    }
    // Never display a password
    final shown = Map<String, dynamic>.of(result);
    for (final f in p.config!.fields.where((f) => f.type == 'password')) {
      if (shown.containsKey(f.id)) shown[f.id] = '********';
    }
    await showDialog(
      context: context,
      builder: (_) => _SuccessDialog(
        rows: [
          for (final f in p.config!.fields)
            if (shown.containsKey(f.id))
              MapEntry(f.label, _display(f, shown[f.id])),
        ],
      ),
    );
    p.reset();
  }
}
String _display(FieldConfig f, dynamic v) {
  if (v == null || (v is String && v.isEmpty)) return '-';
  if (v is bool) return v ? 'Yes' : 'No';
  if (v is List) return v.isEmpty ? '-' : v.join(', ');
  if (f.type == 'file' || f.type == 'image') {
    return v.toString().split(RegExp(r'[/\\]')).last; // file name only
  }
  return v.toString();
}
class _SuccessDialog extends StatelessWidget {
  final List<MapEntry<String, String>> rows;
  const _SuccessDialog({required this.rows});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ---------- Header ----------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(children: [
                // pop-in animation for the check icon
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (_, v, child) => Transform.scale(scale: v, child: child),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, color: Color(0xFF2E7D32), size: 44),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Submitted successfully',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Here is what you entered',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
              ]),
            ),

            // ---------- Values ----------
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                itemCount: rows.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: cs.outlineVariant),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(rows[i].key,
                            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 5,
                        child: Text(rows[i].value,
                            textAlign: TextAlign.right,
                            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ---------- Button ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class FieldRenderer extends StatelessWidget {
  final FieldConfig field;
  const FieldRenderer({super.key, required this.field});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DynamicFormProvider>();
    final f = field;
    final value = p.values[f.id];
    final error = p.errors[f.id];
    final label = f.required ? '${f.label} *' : f.label;

    switch (f.type) {
      case 'text':
      case 'email':
      case 'phone':
      case 'number':
      case 'password':
      case 'textarea':
        return _TextInput(field: f, label: label, error: error, onChanged: (v) => p.setValue(f.id, v));

      case 'dropdown':
        final opts = p.optionsFor(f);
        return DropdownButtonFormField<String>(
          // key changes when parent changes -> dropdown fully resets
          key: ValueKey('${f.id}-${f.dependsOn == null ? '' : p.values[f.dependsOn]}'),
          value: opts.contains(value) ? value : null,
          decoration: InputDecoration(
            labelText: label,
            errorText: error,
            // border: const OutlineInputBorder(),
            helperText: f.dependsOn != null && opts.isEmpty ? 'Select ${f.dependsOn} first' : null,
          ),
          items: opts.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: opts.isEmpty ? null : (v) => p.setValue(f.id, v),
        );

      case 'radio':
        return _group(context, label, error, [
          Wrap(spacing: 8, children: [
            for (final o in f.options)
              ChoiceChip(label: Text(o), selected: value == o, onSelected: (_) => p.setValue(f.id, o)),
          ]),
        ]);

      case 'checkbox':
        final selected = List<String>.from(value ?? []);
        return _group(context, label, error, [
          for (final o in f.options)
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(o),
              value: selected.contains(o),
              onChanged: (c) {
                c == true ? selected.add(o) : selected.remove(o);
                p.setValue(f.id, List<String>.from(selected));
              },
            ),
        ]);

      case 'checkbox_single':
        return _group(context, '', error, [
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(label),
            value: value == true,
            onChanged: (c) => p.setValue(f.id, c == true),
          ),
        ]);

      case 'switch':
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          value: value == true,
          onChanged: (v) => p.setValue(f.id, v),
        );

      case 'slider':
        final min = f.min ?? 0, max = f.max ?? 10;
        final v = ((value as num?)?.toDouble() ?? min).clamp(min, max);
        return _group(context, '$label: ${f.divisions != null ? v.round() : v.toStringAsFixed(1)}', error, [
          Slider(
            value: v,
            min: min,
            max: max,
            divisions: f.divisions,
            label: v.round().toString(),
            onChanged: (x) => p.setValue(f.id, x),
          ),
        ]);

      case 'date':
        return _picker(label, error, value ?? 'Select date', Icons.calendar_today, () async {
          final d = await showDatePicker(
            context: context,
            initialDate: DateTime(2000),
            firstDate: DateTime(1950),
            lastDate: DateTime.now(),
          );
          if (d != null) p.setValue(f.id, d.toIso8601String().split('T').first);
        });

      case 'time':
        return _picker(label, error, value ?? 'Select time', Icons.access_time, () async {
          final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
          if (t != null) {
            p.setValue(f.id, '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
          }
        });

      case 'file':
        final name = value == null ? 'No file selected' : (value as String).split(Platform.pathSeparator).last;
        return _picker(label, error, name, Icons.attach_file, () async {
          final r = await FilePicker.platform.pickFiles(
            type: f.allowedExtensions.isEmpty
                ? FileType.any
                : FileType.custom,
            allowedExtensions: f.allowedExtensions.isEmpty
                ? null
                : f.allowedExtensions,
          );
          final path = r?.files.single.path;
          if (path != null) p.setValue(f.id, path);
        }, helper: f.allowedExtensions.isEmpty ? null : 'Allowed: ${f.allowedExtensions.join(', ')}');

      case 'image':
        return _group(context, label, error, [
          Row(children: [
            if (value != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(value), width: 72, height: 72, fit: BoxFit.cover),
              ),
            if (value != null) const SizedBox(width: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.image),
              label: Text(value == null ? 'Choose image' : 'Change'),
              onPressed: () async {
                final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
                if (x != null) p.setValue(f.id, x.path);
              },
            ),
          ]),
        ]);

      default:
        return Text('Unsupported field type: ${f.type}');
    }
  }

  Widget _group(BuildContext context, String label, String? error, List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (label.isNotEmpty) Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ...children,
      if (error != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
        ),
    ],
  );

  Widget _picker(String label, String? error, String text, IconData icon, VoidCallback onTap, {String? helper}) =>
      InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            errorText: error,
            helperText: helper,
            // border: const OutlineInputBorder(),
            suffixIcon: Icon(icon),
          ),
          child: Text(text),
        ),
      );
}

class _TextInput extends StatefulWidget {
  final FieldConfig field;
  final String label;
  final String? error;
  final ValueChanged<String> onChanged;
  const _TextInput({required this.field, required this.label, required this.error, required this.onChanged});

  @override
  State<_TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<_TextInput> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    final f = widget.field;
    final isPassword = f.type == 'password';
    final isNumeric = f.type == 'number' || f.type == 'phone';

    return TextFormField(
      initialValue: context.read<DynamicFormProvider>().values[f.id]?.toString(),
      obscureText: isPassword && _hidden,
      maxLines: f.type == 'textarea' ? 4 : 1,
      maxLength: f.maxLength,
      keyboardType: switch (f.type) {
        'email' => TextInputType.emailAddress,
        'phone' => TextInputType.phone,
        'number' => TextInputType.number,
        'textarea' => TextInputType.multiline,
        _ => TextInputType.text,
      },
      inputFormatters: isNumeric ? [FilteringTextInputFormatter.digitsOnly] : null,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: f.placeholder,
        errorText: widget.error,
        // border: const OutlineInputBorder(),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(_hidden ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _hidden = !_hidden),
        )
            : null,
      ),
      onChanged: widget.onChanged,
    );
  }
}