import 'package:serverpod_cli/src/commands/create/tui/config.dart';
import 'package:serverpod_cli/src/commands/create/tui/state.dart';
import 'package:serverpod_cli/src/create/create.dart';
import 'package:test/test.dart';

void main() {
  group(
    'Given a CreateConfigState with module template',
    () {
      late CreateConfigState state;

      setUp(() {
        state = CreateConfigState(ServerpodTemplateType.module);
      });

      test('when created then defaults are correct', () {
        expect(state.focusedConfigIndex, 0);
        expect(state.creatingProject, false);
        expect(
          state.configValues,
          containsAll([
            ServerpodCreateConfig.database,
            ServerpodCreateConfig.redis,
          ]),
        );
        expect(
          state.getStateFor(ServerpodCreateConfig.database)?.focusedOptionIndex,
          0,
        );
        expect(
          state.getStateFor(ServerpodCreateConfig.redis)?.focusedOptionIndex,
          0,
        );
      });

      test(
        'then toTemplateContext creates TemplateContext with defaults',
        () {
          final context = state.toTemplateContext();
          expect(context.auth, isFalse);
          expect(context.redis, isTrue);
          expect(context.postgres, isTrue);
          expect(context.sqlite, isFalse);
          expect(context.web, isFalse);
        },
      );
    },
  );

  group('Given a CreateConfigState with server template', () {
    late CreateConfigState state;

    setUp(() {
      state = CreateConfigState(ServerpodTemplateType.server);
    });

    test('when created then defaults are correct', () {
      expect(state.focusedConfigIndex, 0);
      expect(state.creatingProject, false);
      expect(
        state.configValues,
        containsAll([
          ServerpodCreateConfig.database,
          ServerpodCreateConfig.redis,
          ServerpodCreateConfig.web,
          ServerpodCreateConfig.auth,
        ]),
      );
      expect(
        state.getStateFor(ServerpodCreateConfig.database)?.focusedOptionIndex,
        0,
      );
      expect(
        state.getStateFor(ServerpodCreateConfig.redis)?.focusedOptionIndex,
        0,
      );
      expect(
        state.getStateFor(ServerpodCreateConfig.web)?.focusedOptionIndex,
        0,
      );
      expect(
        state.getStateFor(ServerpodCreateConfig.auth)?.focusedOptionIndex,
        0,
      );
    });

    test(
      'then toTemplateContext creates TemplateContext with defaults',
      () {
        final context = state.toTemplateContext();
        expect(context.auth, isTrue);
        expect(context.redis, isTrue);
        expect(context.postgres, isTrue);
        expect(context.sqlite, isFalse);
        expect(context.web, isTrue);
      },
    );

    test(
      'when updating the focused config with positive delta, '
      'then the focused config index is incremented',
      () {
        state.updateFocusedConfig(1);
        expect(state.focusedConfigIndex, 1);
      },
    );

    test(
      'when updating the focused config with positive delta '
      'and the current focused config index is the maximum index,'
      'then the focused config index wraps to 0',
      () {
        for (var i = 0; i < state.configValues.length; i++) {
          state.updateFocusedConfig(1);
        }
        expect(state.focusedConfigIndex, 0);
      },
    );

    test(
      'when updating the focused config with negative delta, '
      'then the focused config index is decremented',
      () {
        state.updateFocusedConfig(1);
        state.updateFocusedConfig(-1);
        expect(state.focusedConfigIndex, 0);
      },
    );

    test(
      'when updating the focused config with negative delta, '
      'and the current focused config index is 0,'
      'then the focused config index wraps to the max config index',
      () {
        state.updateFocusedConfig(-1);
        expect(state.focusedConfigIndex, state.maxFocusedConfigIndex);
      },
    );

    test(
      'when updating the focused config option with positive delta, '
      'then the focused config option index is incremented',
      () {
        final config = state.configValues[state.focusedConfigIndex];
        final configState = state.getStateFor(config);

        final initialIndex = configState!.focusedOptionIndex;
        state.updateFocusedConfigOption(1);

        expect(configState.focusedOptionIndex, initialIndex + 1);
      },
    );

    test(
      'when updating the focused config option with positive delta, '
      'and the current focused config option index is the max, '
      'then the focused config option index wraps to 0',
      () {
        final config = state.configValues[state.focusedConfigIndex];
        final configState = state.getStateFor(config);
        final optionsCount = config.options.length;

        for (var i = 0; i < optionsCount; i++) {
          state.updateFocusedConfigOption(1);
        }

        expect(configState!.focusedOptionIndex, 0);
      },
    );

    test(
      'when updating the focused config option with negative delta, '
      'then the focused config option index is decremented',
      () {
        final config = state.configValues[state.focusedConfigIndex];
        final configState = state.getStateFor(config);
        state.updateFocusedConfigOption(1);
        final indexAfterPositive = configState!.focusedOptionIndex;
        state.updateFocusedConfigOption(-1);
        expect(configState.focusedOptionIndex, indexAfterPositive - 1);
      },
    );

    test(
      'when updating the focused config option with negative delta, '
      'and the current focused config option index is 0, '
      'then the focused config option index wraps to the max config option index',
      () {
        final config = state.configValues[state.focusedConfigIndex];
        final configState = state.getStateFor(config);
        state.updateFocusedConfigOption(-1);
        expect(configState!.focusedOptionIndex, config.options.length - 1);
      },
    );

    test(
      'when selecting config option, '
      'then the selected option is updated',
      () {
        final config = state.configValues.first;
        final expectedOption = config.options[1];
        expect(state.getSelectionOptionFor(config), isNot(expectedOption));

        state.updateFocusedConfigOption(1);
        state.selectConfigOption();

        expect(state.getSelectionOptionFor(config), expectedOption);
      },
    );

    test(
      'when selecting non-postgres database config option, '
      'then config requirements are evaluated for auth config',
      () {
        // Enabled by default
        var authSelection = state.getSelectionOptionFor<BoolConfigOption>(
          ServerpodCreateConfig.auth,
        );

        expect(authSelection, BoolConfigOption.enabled);

        // Move focus to DatabaseConfigOption.none
        state.updateFocusedConfigOption(1);
        state.updateFocusedConfigOption(1);

        // Select focused option
        state.selectConfigOption();

        authSelection = state.getSelectionOptionFor<BoolConfigOption>(
          ServerpodCreateConfig.auth,
        );
        expect(authSelection, BoolConfigOption.disabled);
      },
    );

    test(
      'then getStatus returns true for option that is selected for a config',
      () {
        final status = state.getStatus(
          ServerpodCreateConfig.database,
          DatabaseConfigOption.postgres,
        );

        expect(status, isTrue);
      },
    );

    test(
      'then getStatus returns false for option that is not selected for a config',
      () {
        final status = state.getStatus(
          ServerpodCreateConfig.database,
          DatabaseConfigOption.sqlite,
        );

        expect(status, isFalse);
      },
    );

    test('then getStateFor returns the config state for a config', () {
      final configState = state.getStateFor(ServerpodCreateConfig.database);
      expect(configState, isNotNull);
      expect(configState!.config, ServerpodCreateConfig.database);
      expect(configState.focusedOptionIndex, 0);
    });

    group('when converting to template context', () {
      test(
        'and database is sqlite then TemplateContext has correct value for sqlite',
        () {
          // No need to move focus for the config since database has the initial focus
          // Move focus to sqlite config option
          state.updateFocusedConfigOption(1);
          // Select config option
          state.selectConfigOption();

          final context = state.toTemplateContext();
          expect(context.postgres, isFalse);
          expect(context.sqlite, isTrue);
        },
      );

      test(
        'and database is none then TemplateContext '
        'has correct values for postgres, sqlite and auth',
        () {
          // No need to move focus for the config since database has the initial focus
          // Move focus to none config option
          state.updateFocusedConfigOption(2);
          // Select config option
          state.selectConfigOption();

          final context = state.toTemplateContext();
          expect(context.postgres, isFalse);
          expect(context.sqlite, isFalse);
          expect(context.auth, isFalse);
        },
      );

      test('and redis is disabled then TemplateContext reflects disabled', () {
        // Move focus to redis config
        state.updateFocusedConfig(1);
        // Move focus to disabled config option
        state.updateFocusedConfigOption(1);
        // Select config option
        state.selectConfigOption();

        final context = state.toTemplateContext();
        expect(context.redis, isFalse);
      });

      test('and web is disabled then TemplateContext reflects disabled', () {
        // Move focus to web config
        state.updateFocusedConfig(2);
        // Move focus to disabled config option
        state.updateFocusedConfigOption(1);
        // Select config option
        state.selectConfigOption();

        final context = state.toTemplateContext();
        expect(context.web, isFalse);
      });

      test(
        'with database set to postgres and auth enabled, '
        'then TemplateContext has the correct value for auth',
        () {
          var context = state.toTemplateContext();
          // True by default
          expect(context.auth, isTrue);

          // No need to move focus for the config since database has the initial focus
          // Move focus to sqlite config option
          state.updateFocusedConfigOption(1);
          // Select config option
          state.selectConfigOption();

          context = state.toTemplateContext();
          // False for sqlite
          expect(context.auth, isFalse);

          // Move focus to postgres config option
          state.updateFocusedConfigOption(-1);
          // Select config option
          state.selectConfigOption();

          // Move focus to auth config
          state.updateFocusedConfig(3);
          // Move focus to enabled config option
          state.updateFocusedConfigOption(-1);
          // Select config option
          state.selectConfigOption();

          context = state.toTemplateContext();
          expect(context.auth, isTrue);
        },
      );
    });
  });
}
