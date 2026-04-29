import 'package:serverpod_cli/src/commands/create/tui/config_option.dart';
import 'package:serverpod_cli/src/commands/tui/bounded_queue_list.dart';
import 'package:serverpod_cli/src/commands/tui/state.dart';
import 'package:serverpod_cli/src/create/create.dart';
import 'package:serverpod_cli/src/create/template_context.dart';

class CreateConfigState implements ServerpodState {
  CreateConfigState(this.template)
    : database = SingleChoiceOption<DatabaseType>(
        ConfigOptionId.database,
        'Database',
        DatabaseType.values,
        toDisplayName: (db) => db.displayName,
        defaultValue: DatabaseType.postgres,
      ),
      redis = BoolOption(ConfigOptionId.redis, 'Redis', defaultValue: true),
      web = BoolOption(
        ConfigOptionId.web,
        'Web',
        defaultValue: template.isServer,
      ),
      auth = BoolOption(
        ConfigOptionId.auth,
        'Auth',
        defaultValue: template.isServer,
      );

  final ServerpodTemplateType template;

  final SingleChoiceOption<DatabaseType> database;
  final BoolOption redis;
  final BoolOption web;
  final BoolOption auth;

  List<BoolOption> get boolOptions => [
    redis,
    if (template.isServer) web,
    if (template.isServer) auth,
  ];

  List<SingleChoiceOption> get singleChoiceOptions => [
    if (template.isServer || template.isModule) database,
  ];
  List<ConfigOption> get allOptions => [...singleChoiceOptions, ...boolOptions];

  int selectedIndex = 0;
  int databaseSubIndex = 0;

  bool get databaseExpanded => selectedIndex == 0;

  void _updateDependencies() {
    var hasPostgres = database.isSelectedValue(DatabaseType.postgres);
    auth.enabled = hasPostgres;
  }

  void moveSelection(int delta) {
    var totalOptions = allOptions.length;
    if (databaseExpanded) {
      if (databaseSubIndex == 0 && delta < 0) {
        selectedIndex = totalOptions - 1;
      } else if (databaseSubIndex == 1 && delta > 0) {
        selectedIndex = 1;
      } else {
        databaseSubIndex = (databaseSubIndex + delta + 2) % 2;
      }
    } else {
      selectedIndex = (selectedIndex + delta + totalOptions) % totalOptions;
    }
  }

  void toggleSelected() {
    if (databaseExpanded) {
      database.moveSelection(1);
    } else {
      boolOptions[selectedIndex - 1].select();
    }
    _updateDependencies();
  }

  bool get isDatabaseSqlite => database.isSelectedValue(DatabaseType.sqlite);
  bool get isDatabasePostgres =>
      database.isSelectedValue(DatabaseType.postgres);
  bool get isPostgres => database.isSelectedValue(DatabaseType.postgres);
  bool get isRedisEnabled => redis.value;
  bool get isWebEnabled => web.value;
  bool get isAuthEnabled => auth.value;

  TemplateContext toTemplateContext() {
    return TemplateContext(
      auth: isAuthEnabled,
      redis: isRedisEnabled,
      postgres: isDatabasePostgres,
      sqlite: isDatabaseSqlite,
      web: isWebEnabled,
    );
  }

  @override
  final logHistory = BoundedQueueList<LogEntry>(1000);

  @override
  final Map<String, TrackedOperation> activeOperations = {};

  @override
  final rawLines = BoundedQueueList(0);
}
