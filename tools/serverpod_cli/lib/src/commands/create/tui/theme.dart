import 'package:nocterm/nocterm.dart';

class CreateThemeData {
  const CreateThemeData({
    required this.title,
    required this.optionEnabled,
    required this.optionDisabled,
    required this.optionSelected,
    required this.description,
    required this.hint,
  });

  final Color title;
  final Color optionEnabled;
  final Color optionDisabled;
  final Color optionSelected;
  final Color description;
  final Color hint;

  static const dark = CreateThemeData(
    title: Colors.cyan,
    optionEnabled: Colors.green,
    optionDisabled: Colors.red,
    optionSelected: Colors.magenta,
    description: Colors.white,
    hint: Colors.gray,
  );
}

class CreateTheme extends InheritedComponent {
  const CreateTheme({
    super.key,
    required this.data,
    required super.child,
  });

  final CreateThemeData data;

  static CreateThemeData of(BuildContext context) {
    final widget = context
        .dependOnInheritedComponentOfExactType<CreateTheme>();
    return widget?.data ?? CreateThemeData.dark;
  }

  @override
  bool updateShouldNotify(CreateTheme oldComponent) =>
      data != oldComponent.data;
}