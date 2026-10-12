class ApiResponse<T> {
  const ApiResponse({required this.data, this.code, this.message});

  final T data;
  final int? code;
  final String? message;

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(Object? json) decode) => ApiResponse<T>(
        data: decode(json['data']),
        code: (json['code'] as num?)?.toInt(),
        message: json['message']?.toString(),
      );
}
