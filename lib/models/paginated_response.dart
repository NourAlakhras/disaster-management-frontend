class PaginatedResponse<T> {
  final bool hasNext;
  final bool hasPrev;
  final int page;
  final int totalPages;
  final List<T> items;

  PaginatedResponse({
    required this.hasNext,
    required this.hasPrev,
    required this.page,
    required this.totalPages,
    required this.items,
  });

  factory PaginatedResponse.fromJson(
      Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    return PaginatedResponse<T>(
      hasNext: json['has_next'] ?? false,
      hasPrev: json['has_prev'] ?? false,
      page: json['page'] ?? 1,
      totalPages: json['total_pages'] ?? 0,
      items: (json['items'] as List<dynamic>)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
    );
  }
  @override
  String toString() {
    return 'PaginatedResponse(hasNext: $hasNext, hasPrev: $hasPrev, page: $page, totalPages: $totalPages, items: ${items.toString()})';
  }
}
