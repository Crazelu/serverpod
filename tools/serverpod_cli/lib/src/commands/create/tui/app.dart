import 'package:nocterm/nocterm.dart';
import 'package:serverpod_cli/src/commands/create/tui/state_holder.dart';
import 'package:serverpod_cli/src/commands/tui/app.dart';
import 'package:serverpod_cli/src/commands/tui/components.dart';
import 'package:serverpod_cli/src/create/create.dart';

import 'config_option.dart';
import 'theme.dart';

class ServerpodCreateApp extends ServerpodApp<CreateAppStateHolder> {
  const ServerpodCreateApp({
    super.key,
    required this.onConfirm,
    required this.onQuit,
    required super.holder,
  });

  final VoidCallback onConfirm;
  final VoidCallback onQuit;

  @override
  ServerpodAppState createState() => ServerpodCreateAppState();
}

class ServerpodCreateAppState extends ServerpodAppState<ServerpodCreateApp> {
  final _scrollController = ScrollController();
  final _logScrollController = ScrollController();
  bool _isConfiguringProject = true;

  @override
  void dispose() {
    _scrollController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final theme = CreateTheme.of(context);

    return CreateTheme(
      data: CreateThemeData.dark,
      child: Focusable(
        focused: true,
        onKeyEvent: _handleKeyEvent,
        child: Column(
          children: [
            _buildHeader(theme),
            const SizedBox(height: 1),
            Expanded(
              child: _isConfiguringProject
                  ? _buildForm(theme)
                  : _buildLogView(),
            ),
            const SizedBox(height: 1),
            _buildFooter(theme),
          ],
        ),
      ),
    );
  }

  bool _handleKeyEvent(KeyboardEvent event) {
    final state = component.holder.state;
    switch (event.logicalKey) {
      case LogicalKey.arrowUp:
        state.moveSelection(-1);
        setState(() {});
      case LogicalKey.arrowDown:
        state.moveSelection(1);
        setState(() {});
      case LogicalKey.pageUp:
        _scrollController.scrollUp();
      case LogicalKey.pageDown:
        _scrollController.scrollDown();
      case LogicalKey.enter:
      case LogicalKey.space:
        state.toggleSelected();
        setState(() {});
      case LogicalKey.keyQ:
        component.onQuit();
      case LogicalKey.keyY:
        _isConfiguringProject = false;
        component.onConfirm();
        setState(() {});
    }
    return true;
  }

  Component _buildHeader(CreateThemeData theme) {
    if (!_isConfiguringProject) {
      return Text(
        'Creating Serverpod Project',
        style: TextStyle(
          color: theme.title,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Column(
        children: [
          Text(
            'Create Serverpod Project',
            style: TextStyle(
              color: theme.title,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            'Use arrow keys to navigate, Enter/Space to select, Y to confirm, Q to quit',
            style: TextStyle(
              color: theme.hint,
              fontWeight: FontWeight.dim,
            ),
          ),
        ],
      ),
    );
  }

  Component _buildForm(CreateThemeData theme) {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: ListView(
        controller: _scrollController,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildOptions(theme)),
              const SizedBox(width: 2),
              Expanded(child: _buildPreview(theme)),
            ],
          ),
        ],
      ),
    );
  }

  Component _buildOptions(CreateThemeData theme) {
    var options = component.holder.state.allOptions;
    return Container(
      decoration: BoxDecoration(
        border: BoxBorder.all(
          style: BoxBorderStyle.rounded,
          color: theme.description,
        ),
      ),
      padding: const EdgeInsets.all(1),
      child: Column(
        children: [
          for (var i = 0; i < options.length; i++)
            if (options[i] is SingleChoiceOption)
              _buildSingleChoiceOption(i, theme)
            else
              _buildBoolOption(i, theme),
        ],
      ),
    );
  }

  Component _buildBoolOption(int index, CreateThemeData theme) {
    final state = component.holder.state;
    final option = state.allOptions[index];
    final isSelected = state.selectedIndex == index;
    final isEnabled = option.isEnabled;

    Color labelColor;
    Color statusColor;

    if (isSelected) {
      labelColor = theme.optionSelected;
    } else if (isEnabled) {
      labelColor = theme.optionEnabled;
    } else {
      labelColor = theme.optionDisabled;
    }

    statusColor = isEnabled ? theme.optionEnabled : theme.optionDisabled;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          if (isSelected)
            Text('>', style: TextStyle(color: theme.optionSelected))
          else
            const Text(' '),
          const SizedBox(width: 1),
          Text(
            option.label,
            style: TextStyle(
              color: labelColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 1),
          Text(
            option.statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.dim,
            ),
          ),
        ],
      ),
    );
  }

  Component _buildSingleChoiceOption(int index, CreateThemeData theme) {
    final state = component.holder.state;
    final option = state.allOptions[index] as SingleChoiceOption;
    final isSelected = state.selectedIndex == index;

    Color labelColor = isSelected ? theme.optionSelected : theme.optionEnabled;

    return Container(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              children: [
                if (isSelected)
                  Text('>', style: TextStyle(color: theme.optionSelected))
                else
                  const Text(' '),
                const SizedBox(width: 1),
                Text(
                  option.label,
                  style: TextStyle(
                    color: labelColor,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 1),
                Text(
                  option.statusText,
                  style: TextStyle(
                    color: theme.optionEnabled,
                    fontWeight: FontWeight.dim,
                  ),
                ),
              ],
            ),
          ),
          if (option.isExpanded) _buildSingleOptionChoices(option, theme),
        ],
      ),
    );
  }

  Component _buildSingleOptionChoices<T>(
    SingleChoiceOption<T> option,
    CreateThemeData theme,
  ) {
    var choices = option.choices;
    var selectedChoice = option.selectedChoice;

    return Container(
      padding: const EdgeInsets.only(left: 4),
      child: Column(
        children: [
          for (var i = 0; i < choices.length; i++)
            _buildChoiceItem(i, choices[i], selectedChoice, option, theme),
        ],
      ),
    );
  }

  Component _buildChoiceItem<T>(
    int index,
    T choice,
    T? selectedChoice,
    SingleChoiceOption<T> option,
    CreateThemeData theme,
  ) {
    final state = component.holder.state;
    final isSelected =
        state.databaseExpanded && state.databaseSubIndex == index;
    final isSelectedOption = selectedChoice == choice;
    final choiceLabel = option.choiceDisplayName(choice);

    Color labelColor;
    String statusText;
    Color statusColor;

    if (isSelected) {
      labelColor = theme.optionSelected;
    } else if (isSelectedOption) {
      labelColor = theme.optionEnabled;
    } else {
      labelColor = theme.optionDisabled;
    }

    if (isSelectedOption) {
      statusText = '●';
      statusColor = theme.optionEnabled;
    } else {
      statusText = '○';
      statusColor = theme.optionDisabled;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          if (isSelected)
            Text('>', style: TextStyle(color: theme.optionSelected))
          else
            const Text(' '),
          const SizedBox(width: 1),
          Text(
            choiceLabel,
            style: TextStyle(
              color: labelColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 1),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.dim,
            ),
          ),
        ],
      ),
    );
  }

  Component _buildPreview(CreateThemeData theme) {
    final state = component.holder.state;

    return Container(
      decoration: BoxDecoration(
        border: BoxBorder.all(
          style: BoxBorderStyle.rounded,
          color: theme.description,
        ),
      ),
      padding: const EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuration Preview',
            style: TextStyle(
              color: theme.title,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 1),
          const Divider(color: Colors.gray),
          const SizedBox(height: 1),
          if (!state.template.isMini) ...[
            Text(
              'Database: ${state.database.currentValue}',
              style: TextStyle(color: theme.description),
            ),
            Text(
              'Redis: ${state.redis.value ? "Enabled" : "Disabled"}',
              style: TextStyle(color: theme.description),
            ),
          ],
          if (state.template.isServer) ...[
            Text(
              'Web: ${state.web.value ? "Enabled" : "Disabled"}',
              style: TextStyle(color: theme.description),
            ),
            Text(
              'Auth: ${state.auth.enabled ? (state.auth.value ? "Enabled" : "Disabled") : "Requires PostgreSQL"}',
              style: TextStyle(color: theme.description),
            ),
            if (!state.isPostgres) ...[
              const SizedBox(height: 1),
              Text(
                'Note: Auth requires PostgreSQL',
                style: TextStyle(
                  color: theme.hint,
                  fontWeight: FontWeight.dim,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Component _buildFooter(CreateThemeData theme) {
    return Row(
      children: [
        if (_isConfiguringProject) ...[
          Text(
            'Y',
            style: TextStyle(
              color: theme.optionEnabled,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(' Confirm  '),
        ],
        Text(
          'Q',
          style: TextStyle(
            color: theme.hint,
            fontWeight: FontWeight.dim,
          ),
        ),
        const Text(' Quit'),
      ],
    );
  }

  Component _buildLogView() {
    return LogViewerWidget(
      state: component.holder.state,
      scrollController: _logScrollController,
    );
  }
}
