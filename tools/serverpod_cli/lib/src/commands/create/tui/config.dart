/// Configuration for [ServerpodCreateApp].
/// The enum values are mapped to the configurable features
/// for the `serverpod create` command, typically held by [TemplateContext].
enum ServerpodCreateConfig<T extends ConfigOption> {
  database<DatabaseConfigOption>(
    label: 'Database',
    options: DatabaseConfigOption.values,
    defaultOption: DatabaseConfigOption.postgres,
  ),
  redis<BoolConfigOption>(
    label: 'Redis (inter-server pubsub & caching)',
    options: BoolConfigOption.values,
    defaultOption: BoolConfigOption.enabled,
  ),
  web<BoolConfigOption>(
    label: 'Webserver',
    options: BoolConfigOption.values,
    defaultOption: BoolConfigOption.enabled,
  ),
  auth<BoolConfigOption>(
    label: 'Authentication (requires Postgres)',
    options: BoolConfigOption.values,
    defaultOption: BoolConfigOption.enabled,
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
    this.requirements = const [],
  });

  final String label;
  final List<T> options;
  final T defaultOption;
  final List<ConfigRequirement> requirements;
}

/// Represents an option for [ServerpodCreateConfig].
abstract class ConfigOption {
  String get label;
}

/// Binary [ConfigOption] that can either be [enabled] or [disabled].
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
