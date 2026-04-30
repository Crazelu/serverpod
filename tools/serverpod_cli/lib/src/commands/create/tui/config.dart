import 'package:serverpod_cli/src/create/create.dart';

/// Configuration for [ServerpodCreateApp].
/// The enum values are mapped to the configurable features
/// for the `serverpod create` command, typically held by [TemplateContext].
enum ServerpodCreateConfig<T extends ConfigOption> {
  database<DatabaseConfigOption>(
    label: 'Database',
    options: DatabaseConfigOption.values,
    defaultOption: DatabaseConfigOption.postgres,
    templates: [ServerpodTemplateType.server, ServerpodTemplateType.module],
  ),
  redis<BoolConfigOption>(
    label: 'Redis (inter-server pubsub & caching)',
    options: BoolConfigOption.values,
    defaultOption: BoolConfigOption.enabled,
    templates: [ServerpodTemplateType.server, ServerpodTemplateType.module],
  ),
  web<BoolConfigOption>(
    label: 'Webserver',
    options: BoolConfigOption.values,
    defaultOption: BoolConfigOption.enabled,
    templates: [ServerpodTemplateType.server],
  ),
  auth<BoolConfigOption>(
    label: 'Authentication (requires Postgres)',
    options: BoolConfigOption.values,
    defaultOption: BoolConfigOption.enabled,
    templates: [ServerpodTemplateType.server],
    requirements: [
      ConfigRequirement(
        requiredConfig: ServerpodCreateConfig.database,
        requiredConfigOption: DatabaseConfigOption.postgres,
        disabledOption: BoolConfigOption.disabled,
      ),
    ],
  )
  ;

  const ServerpodCreateConfig({
    required this.label,
    required this.options,
    required this.defaultOption,
    required this.templates,
    this.requirements = const [],
  });

  /// UI visible label for this config.
  final String label;

  /// Supported config options.
  final List<T> options;

  /// The default config option.
  final T defaultOption;

  /// Requirements for other related configs that must be satisfied
  /// for this config to be enabled.
  final List<ConfigRequirement> requirements;

  /// Supported template types for this config.
  final List<ServerpodTemplateType> templates;
}

/// A [ServerpodCreateConfig] option.
abstract class ConfigOption {
  String get label;
}

/// [ConfigOption] that can either be [enabled] or [disabled].
enum BoolConfigOption implements ConfigOption {
  enabled('Enabled'),
  disabled('Disabled')
  ;

  const BoolConfigOption(this.label);

  @override
  final String label;
}

/// [ConfigOption] for supported databases.
enum DatabaseConfigOption implements ConfigOption {
  postgres('Postgres'),
  sqlite('SQLite'),
  none('None')
  ;

  const DatabaseConfigOption(this.label);

  @override
  final String label;
}

/// Represents a requirement for [ServerpodCreateConfig].
class ConfigRequirement<T extends ConfigOption> {
  const ConfigRequirement({
    required this.requiredConfig,
    required this.requiredConfigOption,
    required this.disabledOption,
  });

  /// The required config. The selected option for this config
  /// must be [requiredConfigOption] for the requirement to be satisfied.
  final ServerpodCreateConfig<T> requiredConfig;

  /// The option for [requiredConfig] that must be satisified.
  final T requiredConfigOption;

  /// Option to set if this requirement is not satisfied.
  final ConfigOption disabledOption;
}
