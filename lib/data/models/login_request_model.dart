class LoginRequestModel {
  final String identifier;
  final String password;
  final Map<String, dynamic>? device;

  LoginRequestModel({
    required this.identifier,
    required this.password,
    this.device,
  });

  factory LoginRequestModel.fromJson(Map<String, dynamic> json) =>
      LoginRequestModel(
        identifier: (json['identifier'] ?? '').toString(),
        password: (json['password'] ?? '').toString(),
        device: json['device'] as Map<String, dynamic>?,
      );

  Map<String, dynamic> toJson() => {
        'identifier': identifier,
        'password': password,
        if (device != null) 'device': device,
      };
}
