class AdbDevice {
  final String serial;
  final String status;
  bool selected;

  AdbDevice({
    required this.serial,
    required this.status,
    this.selected = false,
  });

  bool get isAvailable => status == 'device';
}
