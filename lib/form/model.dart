class VisibleIf {
  final String field;
  final dynamic equals, notEquals;
  VisibleIf(this.field, this.equals, this.notEquals);

  factory VisibleIf.fromJson(Map<String, dynamic> j) =>
      VisibleIf(j['field'], j['equals'], j['notEquals']);

  bool evaluate(Map<String, dynamic> values) {
    final v = values[field];
    if (equals != null) return v == equals;
    if (notEquals != null) return v != notEquals;
    return true;
  }
}

class FieldConfig {
  final String id, type, label;
  final String? placeholder, dependsOn;
  final bool required;
  final int? minLength, maxLength, divisions;
  final double? min, max;
  final List<String> options, allowedExtensions;
  final Map<String, List<String>> optionsMap;
  final VisibleIf? visibleIf;

  FieldConfig({
    required this.id,
    required this.type,
    required this.label,
    this.placeholder,
    this.dependsOn,
    this.required = false,
    this.minLength,
    this.maxLength,
    this.divisions,
    this.min,
    this.max,
    this.options = const [],
    this.allowedExtensions = const [],
    this.optionsMap = const {},
    this.visibleIf,
  });

  factory FieldConfig.fromJson(Map<String, dynamic> j) => FieldConfig(
    id: j['id'],
    type: j['type'],
    label: j['label'] ?? j['id'],
    placeholder: j['placeholder'],
    dependsOn: j['dependsOn'],
    required: j['required'] == true,
    minLength: j['minLength'],
    maxLength: j['maxLength'],
    divisions: j['divisions'],
    min: (j['min'] as num?)?.toDouble(),
    max: (j['max'] as num?)?.toDouble(),
    options: (j['options'] as List?)?.map((e) => e.toString()).toList() ?? [],
    allowedExtensions: (j['allowedExtensions'] as List?)?.map((e) => e.toString()).toList() ?? [],
    optionsMap: (j['optionsMap'] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), (v as List).map((e) => e.toString()).toList()),
    ) ??
        {},
    visibleIf: j['visibleIf'] == null ? null : VisibleIf.fromJson(j['visibleIf']),
  );
}

class FormConfig {
  final String title, submitButton;
  final List<FieldConfig> fields;
  FormConfig(this.title, this.submitButton, this.fields);

  factory FormConfig.fromJson(Map<String, dynamic> j) => FormConfig(
    j['title'] ?? 'Form',
    j['submitButton'] ?? 'Submit',
    (j['fields'] as List).map((e) => FieldConfig.fromJson(e)).toList(),
  );
}