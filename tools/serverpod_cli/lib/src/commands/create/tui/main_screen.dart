import 'package:nocterm/nocterm.dart';
import 'package:serverpod_cli/src/commands/create/tui/config.dart';
import 'package:serverpod_cli/src/commands/create/tui/state_holder.dart';
import 'package:serverpod_cli/src/commands/tui/components.dart';
import 'package:serverpod_cli/src/commands/tui/help_overlay.dart';
import 'package:serverpod_cli/src/commands/tui/serverpod_theme.dart';

class MainScreen extends StatelessComponent {
  const MainScreen({
    super.key,
    required this.holder,
    required this.scrollController,
    required this.logScrollController,
    required this.onCreate,
    required this.onQuit,
    required this.onToggleHelp,
  });

  final CreateAppStateHolder holder;
  final ScrollController scrollController;
  final ScrollController logScrollController;
  final VoidCallback onCreate;
  final VoidCallback onQuit;
  final VoidCallback onToggleHelp;

  static const _helpBindings = [
    (
      'Navigation',
      [
        ('k', 'Scroll up'),
        ('j', 'Scroll down'),
        ('Shift+↑', 'Scroll up ¼ screen'),
        ('Shift+↓', 'Scroll down ¼ screen'),
        ('u / Ctrl+u', 'Scroll up ½ screen'),
        ('d / Ctrl+d', 'Scroll down ½ screen'),
        ('PgUp / b / Backspace', 'Scroll up one screen'),
        ('PgDn / Space / f', 'Scroll down one screen'),
        ('Home / g', 'Go to start'),
        ('End / G', 'Go to end'),
      ],
    ),
    (
      'Actions',
      [
        ('Enter', 'Create project'),
        ('Space', 'Select option'),
        ('←↑↓→', 'Navigate through options'),
        ('Q', 'Quit'),
      ],
    ),
  ];

  @override
  Component build(BuildContext context) {
    final theme = ServerpodTheme.of(context);
    final state = holder.state;
    final creatingProject = state.creatingProject;

    return Stack(
      children: [
        Column(
          children: [
            _buildHeader(theme),
            Expanded(
              child: creatingProject ? _buildLogView() : _buildForm(theme),
            ),
            const SizedBox(height: 1),
            _buildFooter(theme),
            const SizedBox(height: 1),
          ],
        ),
        if (state.showHelp) const HelpOverlay(bindings: _helpBindings),
      ],
    );
  }

  Component _buildHeader(ServerpodThemeData theme) {
    final creatingProject = holder.state.creatingProject;
    final prefix = creatingProject ? 'Creating' : 'Configure Your';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Column(
        children: [
          Text(
            '$prefix Serverpod Project',
            style: TextStyle(
              color: theme.activeTab,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Component _buildForm(ServerpodThemeData theme) {
    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,
      child: ListView(
        controller: scrollController,
        children: [_buildConfigurations(theme)],
      ),
    );
  }

  Component _buildConfigurations(ServerpodThemeData theme) {
    final state = holder.state;
    final configurations = state.configValues;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final config in configurations.indexed) ...[
          _buildConfiguration(
            theme,
            config.$2,
            config.$1 == state.focusedConfigIndex,
          ),
          const SizedBox(height: 1),
        ],
      ],
    );
  }

  Component _buildConfiguration(
    ServerpodThemeData theme,
    ServerpodCreateConfig config,
    bool focused,
  ) {
    final state = holder.state;
    final selectedOption = state.getSelectionOptionFor(config);

    bool isOptionFocused(int optionIndex) {
      return focused &&
          state.getStateFor(config)?.focusedOptionIndex == optionIndex;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          config.label,
          style: TextStyle(
            fontWeight: focused ? FontWeight.bold : FontWeight.dim,
          ),
        ),
        const SizedBox(height: 1),
        Row(
          children: [
            for (final option in config.options.indexed) ...[
              _buildConfigurationOption(
                theme,
                option.$2,
                selectedOption == option.$2,
                isOptionFocused(option.$1),
              ),
              const SizedBox(width: 2),
            ],
          ],
        ),
      ],
    );
  }

  Component _buildConfigurationOption(
    ServerpodThemeData theme,
    ConfigOption option,
    bool selected,
    bool focused,
  ) {
    return RadioButton(
      label: option.label,
      focused: focused,
      value: selected,
    );
  }

  Component _buildFooter(ServerpodThemeData theme) {
    final state = holder.state;
    final creatingProject = state.creatingProject;
    return Row(
      children: [
        Button(
          name: 'Create Project',
          activationChar: 'Enter',
          enabled: !creatingProject,
          activationKeys: const [LogicalKey.enter],
          onActivate: (_) {
            state.markCreatingProject();
            holder.markDirty();
            onCreate.call();
          },
        ),
        const SizedBox(width: 2),

        Button(
          name: 'Navigate',
          activationChar: '←↑↓→',
          enabled: !creatingProject,
          activationKeys: const [
            LogicalKey.arrowUp,
            LogicalKey.arrowDown,
            LogicalKey.arrowLeft,
            LogicalKey.arrowRight,
          ],
          onActivate: (key) {
            switch (key) {
              case LogicalKey.arrowUp:
                state.updateFocusedConfig(-1);
                if (state.focusedConfigIndex == state.maxFocusedConfigIndex) {
                  scrollController.scrollToEnd();
                } else {
                  scrollController.scrollUp(4);
                }
                break;
              case LogicalKey.arrowDown:
                state.updateFocusedConfig(1);
                if (state.focusedConfigIndex == 0) {
                  scrollController.scrollToStart();
                } else {
                  scrollController.scrollDown(4);
                }
                break;
              case LogicalKey.arrowLeft:
                state.updateFocusedConfigOption(-1);
                break;
              case LogicalKey.arrowRight:
                state.updateFocusedConfigOption(1);
                break;
            }
            holder.markDirty();
          },
        ),
        const SizedBox(width: 2),
        Button(
          name: 'Select',
          activationChar: 'Space',
          enabled: !creatingProject,
          activationKeys: const [LogicalKey.space],
          onActivate: (_) {
            state.selectConfigOption();
            holder.markDirty();
          },
        ),
        const SizedBox(width: 2),
        Button(
          name: 'Help',
          activationChar: 'H',
          activationKeys: const [LogicalKey.keyH],
          onActivate: (_) {
            onToggleHelp.call();
          },
        ),
        const SizedBox(width: 2),
        Button(
          name: 'Quit',
          activationChar: 'Q',
          activationKeys: const [LogicalKey.keyQ],
          onActivate: (_) {
            onQuit.call();
          },
        ),
      ],
    );
  }

  Component _buildLogView() {
    return LogViewerWidget(
      state: holder.state,
      scrollController: logScrollController,
    );
  }
}
