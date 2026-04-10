class AdbDevice {
  final String serial;
  final String status;
  final String? usb;
  final String? product;
  final String? model;
  final String? device;
  final String? transportId;
  bool selected;

  AdbDevice({
    required this.serial,
    required this.status,
    this.usb,
    this.product,
    this.model,
    this.device,
    this.transportId,
    this.selected = false,
  });

  bool get isAvailable => status == 'device';

  String get displayModel =>
      model?.replaceAll('_', ' ') ?? serial;
}
