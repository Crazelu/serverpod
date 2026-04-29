import 'package:nocterm/nocterm.dart';
import 'package:serverpod_cli/src/commands/tui/app_state_holder.dart';

abstract class ServerpodApp<T extends ServerpodAppStateHolder>
    extends StatefulComponent {
  const ServerpodApp({super.key, required this.holder});

  final T holder;

  @override
  ServerpodAppState<ServerpodApp> createState();
}

abstract class ServerpodAppState<S extends ServerpodApp> extends State<S> {
  @override
  void initState() {
    super.initState();
    component.holder.attach(this);
  }

  @override
  void setState(VoidCallback fn) {
    if (!mounted) return;
    super.setState(fn);
  }

  @override
  void dispose() {
    component.holder.detach(this);
    super.dispose();
  }

  void rebuild() {
    setState(() {});
  }
}
