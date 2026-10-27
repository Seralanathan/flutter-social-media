  import 'dart:convert';
  import 'package:flutter/foundation.dart';
  import 'package:flutter/services.dart';

  import 'model.dart';

  class DynamicFormProvider extends ChangeNotifier {
    FormConfig? config;
    final values = <String, dynamic>{};
    final errors = <String, String?>{};
    bool _submitted = false;
    int resetCount = 0;

    Future<void> loadFromAsset(String path) async {
      loadFromJson(jsonDecode(await rootBundle.loadString(path)));
    }

    void loadFromJson(Map<String, dynamic> json) {
      config = FormConfig.fromJson(json);
      _initValues();
      notifyListeners();
    }

    void _initValues() {
      values.clear();
      errors.clear();
      _submitted = false;
      for (final f in config!.fields) {
        values[f.id] = switch (f.type) {
          'checkbox' => <String>[],
          'switch' || 'checkbox_single' => false,
          'slider' => f.min ?? 0.0,
          _ => null,
        };
      }
    }

    void reset() {
      if (config == null) return;
      _initValues();
      resetCount++; // changes the field keys, see Step 3
      notifyListeners();
    }

    FieldConfig _byId(String id) => config!.fields.firstWhere((f) => f.id == id);

    bool isVisible(FieldConfig f) => f.visibleIf?.evaluate(values) ?? true;
    List<FieldConfig> get visibleFields => config?.fields.where(isVisible).toList() ?? [];

    /// Static options, or options chosen by the parent's current value.
    List<String> optionsFor(FieldConfig f) =>
        f.dependsOn != null ? (f.optionsMap[values[f.dependsOn]] ?? const []) : f.options;

    void setValue(String id, dynamic v) {
      values[id] = v;
      // Reset children (country changed -> clear state)
      for (final f in config!.fields.where((f) => f.dependsOn == id)) {
        values[f.id] = null;
        errors.remove(f.id);
      }
      if (_submitted) errors[id] = _validate(_byId(id), v);
      notifyListeners(); // also re-evaluates visibleIf
    }

    String? _validate(FieldConfig f, dynamic v) {
      final empty = v == null ||
          (v is String && v.trim().isEmpty) ||
          (v is List && v.isEmpty) ||
          (f.type == 'checkbox_single' && v != true);

      if (f.required && empty) {
        return f.type == 'checkbox_single' ? 'You must accept to continue' : '${f.label} is required';
      }
      if (empty) return null;

      if (v is String) {
        if (f.minLength != null && v.length < f.minLength!) return 'Minimum ${f.minLength} characters';
        if (f.maxLength != null && v.length > f.maxLength!) return 'Maximum ${f.maxLength} characters';
      }
      switch (f.type) {
        case 'email':
          if (!RegExp(r'^[\w.\-+]+@[\w\-]+(\.[\w\-]+)+$').hasMatch(v)) return 'Enter a valid email';
        case 'phone':
          if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v)) return 'Enter a valid 10-digit mobile number';
        case 'number':
          final n = num.tryParse(v);
          if (n == null) return 'Enter a valid number';
          if (f.min != null && n < f.min!) return 'Must be at least ${f.min!.toInt()}';
          if (f.max != null && n > f.max!) return 'Must be at most ${f.max!.toInt()}';
      }
      return null;
    }

    /// Validates visible fields only. Returns cleaned values, or null if invalid.
    Map<String, dynamic>? submit() {
      _submitted = true;
      errors.clear();
      var ok = true;
      for (final f in visibleFields) {
        final e = _validate(f, values[f.id]);
        errors[f.id] = e;
        if (e != null) ok = false;
      }
      notifyListeners();
      if (!ok) return null;

      // Hidden fields are excluded; numbers are converted to real numbers
      return {
        for (final f in visibleFields)
          f.id: switch (f.type) {
            'number' => num.tryParse(values[f.id] ?? ''),
            'slider' => f.divisions != null ? (values[f.id] as double).round() : values[f.id],
            _ => values[f.id],
          }
      };
    }
  }