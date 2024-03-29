import 'package:flutter/material.dart';

class SliverResponsiveAppBar extends StatelessWidget {
  const SliverResponsiveAppBar({
    this.title,
    this.actions,
    super.key,
  });

  // cspell:disable-next-line
  /// {@macro flutter.material.appbar.title}
  final Widget? title;

  // cspell:disable-next-line
  /// {@macro flutter.material.appbar.actions}
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final floating = constraints.viewportMainAxisExtent > 400;
        return SliverAppBar(
          floating: floating,
          snap: floating,
          title: title,
          actions: actions,
        );
      },
    );
  }
}
