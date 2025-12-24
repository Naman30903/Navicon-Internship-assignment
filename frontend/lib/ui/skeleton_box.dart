import 'package:flutter/material.dart';
import 'package:frontend/constant/padding.dart';
import 'package:frontend/constant/radii.dart';

class SkeletonBox extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius borderRadius;

  const SkeletonBox({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: borderRadius,
      ),
    );
  }
}

class SummaryRowSkeleton extends StatelessWidget {
  const SummaryRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: SkeletonBox(height: 84)),
        SizedBox(width: AppSpace.md),
        Expanded(child: SkeletonBox(height: 84)),
        SizedBox(width: AppSpace.md),
        Expanded(child: SkeletonBox(height: 84)),
      ],
    );
  }
}

class TaskListSkeletonSliver extends StatelessWidget {
  final int itemCount;
  const TaskListSkeletonSliver({super.key, required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpace.md),
      itemBuilder: (_, __) => const SkeletonBox(
        height: 120,
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.lg)),
      ),
    );
  }
}
