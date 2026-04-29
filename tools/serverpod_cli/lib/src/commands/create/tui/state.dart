import 'package:serverpod_cli/src/commands/create/tui/config.dart';
import 'package:serverpod_cli/src/commands/tui/bounded_queue_list.dart';
import 'package:serverpod_cli/src/commands/tui/state.dart';
import 'package:serverpod_cli/src/create/create.dart';
import 'package:serverpod_cli/src/create/template_context.dart';

/// Central state for [ServerpodCreateApp] rendered by nocterm.
class CreateConfigState extends ServerpodState {
  CreateConfigState(this.template) {
    configValues = ServerpodCreateConfig.values;
    _stateValues = {};
    _optionStateValues = {};
    for (final config in configValues) {
      _stateValues[config] = config.defaultOption;
      _optionStateValues[config] = ServerpodCreateConfigState(config);
    }
  }

  final ServerpodTemplateType template;

  late final List<ServerpodCreateConfig> configValues;

  /// Tracked state for selected [ConfigOption] per [ServerpodCreateConfig].
  late final Map<ServerpodCreateConfig, ConfigOption> _stateValues;

  /// Tracked state for focused [ConfigOption] per [ServerpodCreateConfig].
  late final Map<ServerpodCreateConfig, ServerpodCreateConfigState>
  _optionStateValues;

  late final int maxFocusedConfigIndex = configValues.length - 1;

  bool _creatingProject = false;
  bool get creatingProject => _creatingProject;

  int _focusedConfigIndex = 0;
  int get focusedConfigIndex => _focusedConfigIndex;

  @override
  final logHistory = BoundedQueueList<LogEntry>(1000);

  @override
  final Map<String, TrackedOperation> activeOperations = {};

  @override
  final rawLines = BoundedQueueList(0);

  /// Called when project creation starts.
  /// This transitions the UI to a log viewer.
  void markCreatingProject() {
    _creatingProject = true;
  }

  /// Updates the focused [ServerpodCreateConfig].
  void updateFocusedConfig(int delta) {
    _focusedConfigIndex += delta;
    if (_focusedConfigIndex > maxFocusedConfigIndex) {
      _focusedConfigIndex = 0;
    } else if (_focusedConfigIndex < 0) {
      _focusedConfigIndex = maxFocusedConfigIndex;
    }
  }

  /// Updates the focused [ConfigOption] for the focused [ServerpodCreateConfig].
  void updateFocusedConfigOption(int delta) {
    final config = configValues[_focusedConfigIndex];
    final configState = _optionStateValues[config];
    configState?._updateFocusedOption(delta);
  }

  /// Selects the current focused config option for the focused config.
  void selectConfigOption() {
    final config = configValues[_focusedConfigIndex];
    final configState = _optionStateValues[config];
    if (configState == null) return;
    final focusedOptionIndex = configState.focusedOptionIndex;
    final newSelection = configState.config.options[focusedOptionIndex];
    _stateValues[config] = newSelection;
    _evaluateRequirements();
  }

  /// Evaluates requirements defined for each [ServerpodCreateConfig].
  void _evaluateRequirements() {
    for (final config in configValues) {
      if (config.requirements.isEmpty) continue;
      for (final req in config.requirements) {
        final selectedOption = getSelectionOptionFor(req.requiredConfig);
        if (selectedOption != req.requiredConfigOption) {
          _stateValues[config] = req.disabledOption;
          final configState = _optionStateValues[config];
          // Update the focused option index to keep UI interaction in sync
          configState?._focusedOptionIndex = config.options.indexOf(
            req.disabledOption,
          );
        }
      }
    }
  }

  /// Returns the [ServerpodCreateConfigState] for [config].
  /// This is typically used to retrieve the focused option for a [config].
  ServerpodCreateConfigState? getStateFor<T extends ConfigOption>(
    ServerpodCreateConfig<T> config,
  ) {
    return _optionStateValues[config];
  }

  /// Returns the selected [ConfigOption] for [config].
  T getSelectionOptionFor<T extends ConfigOption>(
    ServerpodCreateConfig<T> config,
  ) {
    return _stateValues[config] as T;
  }

  /// Returns true if [option] is the selected option for [config].
  bool getStatus<T extends ConfigOption>(
    ServerpodCreateConfig<T> config,
    T option,
  ) {
    return _stateValues[config] == option;
  }

  /// Converts this state to [TemplateContext].
  TemplateContext toTemplateContext() {
    return TemplateContext(
      auth: getStatus(ServerpodCreateConfig.auth, BoolConfigOption.enabled),
      redis: getStatus(
        ServerpodCreateConfig.redis,
        BoolConfigOption.enabled,
      ),
      postgres: getStatus(
        ServerpodCreateConfig.database,
        DatabaseConfigOption.postgres,
      ),
      sqlite: getStatus(
        ServerpodCreateConfig.database,
        DatabaseConfigOption.sqlite,
      ),
      web: getStatus(ServerpodCreateConfig.web, BoolConfigOption.enabled),
    );
  }
}

/// Internal state of [config] tracking the focused option.
class ServerpodCreateConfigState<T extends ServerpodCreateConfig> {
  ServerpodCreateConfigState(this.config)
    : _maxIndex = config.options.length - 1;

  final T config;
  final int _maxIndex;

  int _focusedOptionIndex = 0;
  int get focusedOptionIndex => _focusedOptionIndex;

  void _updateFocusedOption(int delta) {
    _focusedOptionIndex += delta;
    if (_focusedOptionIndex > _maxIndex) {
      _focusedOptionIndex = 0;
    } else if (_focusedOptionIndex < 0) {
      _focusedOptionIndex = _maxIndex;
    }
  }
}
