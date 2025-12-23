import 'package:flutter/material.dart';
import 'package:frontend/constant/padding.dart';

class TaskListLayout extends StatelessWidget {
  final Widget summary;
  final Widget body;

  const TaskListLayout({super.key, required this.summary, required this.body});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = AppSpace.horizontalPaddingForWidth(
          constraints.maxWidth,
        );

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: AppSpace.lg,
                ),
                child: summary,
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                AppSpace.xl,
              ),
              sliver: body,
            ),
          ],
        );
      },
    );
  }
}
