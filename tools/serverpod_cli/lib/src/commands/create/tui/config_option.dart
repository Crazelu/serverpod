enum ConfigOptionId {
  database,
  redis,
  web,
  auth,
}

enum DatabaseType {
  postgres('PostgreSQL'),
  sqlite('SQLite');

  const DatabaseType(this.displayName);
  final String displayName;
}

abstract class ConfigOption {
  ConfigOption(this._id, this._label, {bool defaultValue = false})
    : _value = defaultValue,
      _isSelected = false;

  final ConfigOptionId _id;
  final String _label;

  bool _value;
  bool _isSelected;

  ConfigOptionId get id => _id;
  String get label => _label;
  bool get value => _value;
  bool get isSelected => _isSelected;
  bool get isExpanded => false;
  bool get isEnabled => _value;

  String get statusText => _value ? '✓' : '○';

  void select() => _isSelected = !_isSelected;
  void setSelected(bool selected) => _isSelected = selected;
  void moveSelection(int delta) {}
}

class BoolOption extends ConfigOption {
  BoolOption(
    ConfigOptionId id,
    String label, {
    super.defaultValue = false,
    bool enabled = true,
  }) : _enabled = enabled,
       super(id, label);

  bool _enabled;
  bool get enabled => _enabled;
  set enabled(bool value) => _enabled = value;

  @override
  bool get isEnabled => _enabled && _value;

  @override
  String get statusText => _enabled ? (_value ? '✓' : '○') : '(disabled)';

  @override
  void select() {
    if (_enabled) _value = !_value;
  }
}

class SingleChoiceOption<T> extends ConfigOption
    implements ConfigOptionIdHelper<T> {
  SingleChoiceOption(
    ConfigOptionId id,
    String label,
    List<T> choices, {
    required String Function(T) toDisplayName,
    T? defaultValue,
    bool enabled = true,
  }) : _choices = choices,
       _toDisplayName = toDisplayName,
       _defaultChoice = defaultValue,
       _enabled = enabled,
       _selectedChoice = defaultValue,
       super(id, label);

  final List<T> _choices;
  final String Function(T) _toDisplayName;
  final T? _defaultChoice;
  final bool _enabled;
  T? _selectedChoice;

  @override
  bool get enabled => _enabled;
  @override
  bool get isExpanded => true;
  @override
  List<T> get choices => _choices;
  @override
  T? get selectedChoice => _selectedChoice;
  @override
  bool get isEnabled => _selectedChoice != null;

  @override
  String get currentValue =>
      _selectedChoice == null ? 'None' : _toDisplayName(_selectedChoice as T);

  @override
  String choiceDisplayName(T choice) => _toDisplayName(choice);

  @override
  String get statusText => currentValue;

  @override
  int get selectedIndex =>
      _selectedChoice == null ? -1 : _choices.indexOf(_selectedChoice as T);

  @override
  bool get isSelected => selectedIndex == 0;

  @override
  void moveSelection(int delta) {
    if (!_enabled) return;
    if (_selectedChoice == null) {
      _selectedChoice = _choices.first;
      return;
    }
    var newIndex = (selectedIndex + delta + _choices.length) % _choices.length;
    _selectedChoice = _choices[newIndex];
  }

  @override
  bool isSelectedValue(T value) => _selectedChoice == value;

  @override
  void reset() => _selectedChoice = _defaultChoice;
}

abstract class ConfigOptionIdHelper<T> {
  ConfigOptionId get id;
  String get label;
  bool get enabled;
  bool get isExpanded;
  List<T> get choices;
  T? get selectedChoice;
  bool get isEnabled;
  String get currentValue;
  String get statusText;
  int get selectedIndex;
  bool get isSelected;
  void moveSelection(int delta);
  bool isSelectedValue(T value);
  void reset();
  String choiceDisplayName(T choice);
}
