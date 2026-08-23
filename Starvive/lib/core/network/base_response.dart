class BaseResponse<T> {
  BaseResponse({this.code, this.data, this.message});

  factory BaseResponse.fromJson(
    Map<String, dynamic> json,
    T? Function(dynamic)? fromJsonT,
  ) {
    return BaseResponse(
      code: json['code'] as int?,
      message: json['message'] as String?,
      data: fromJsonT != null ? fromJsonT(json['data']) : json['data'] as T?,
    );
  }

  final int? code;
  final T? data;
  final String? message;

  bool get isSuccess => code == 0;
}

class PageResult<T> {
  PageResult({
    this.records,
    this.pageNumber,
    this.pageSize,
    this.totalPage,
    this.totalRow,
  });

  factory PageResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final recordsJson = json['records'] as List<dynamic>? ?? [];
    return PageResult(
      records: recordsJson
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      pageNumber: json['pageNumber'] as int?,
      pageSize: json['pageSize'] as int?,
      totalPage: json['totalPage'] as int?,
      totalRow: json['totalRow'] as int?,
    );
  }

  final List<T>? records;
  final int? pageNumber;
  final int? pageSize;
  final int? totalPage;
  final int? totalRow;
}
