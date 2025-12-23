import 'package:flutter/foundation.dart';

@immutable
class PaginationModel {
  final int total;
  final int limit;
  final int offset;
  final int totalPages;

  const PaginationModel({
    required this.total,
    required this.limit,
    required this.offset,
    required this.totalPages,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      total: json['total'] as int,
      limit: json['limit'] as int,
      offset: json['offset'] as int,
      totalPages: json['totalPages'] as int,
    );
  }

  bool get hasMore => offset + limit < total;
  int get currentPage => (offset / limit).floor() + 1;

  @override
  String toString() =>
      'PaginationModel(total: $total, page: $currentPage/$totalPages)';
}
