import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum DeviceType {
  bluetooth,
  wifi,
  usb,
}

enum ConnectionStatus {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

class RoasterDevice {
  final String id;
  final String name;
  final DeviceType type;
  final String? model;
  final String? manufacturer;
  
  // 蓝牙设备特有
  final BluetoothDevice? bluetoothDevice;
  final int? rssi;
  
  // WiFi设备特有
  final String? ipAddress;
  final int? port;

  ConnectionStatus status = ConnectionStatus.disconnected;
  DateTime? lastConnected;

  RoasterDevice({
    required this.id,
    required this.name,
    required this.type,
    this.model,
    this.manufacturer,
    this.bluetoothDevice,
    this.rssi,
    this.ipAddress,
    this.port,
  });

  bool get isConnected => status == ConnectionStatus.connected;

  String get displayName => name.isNotEmpty ? name : 'Unknown Device';
  
  String get connectionInfo {
    switch (type) {
      case DeviceType.bluetooth:
        return rssi != null ? 'BLE • ${rssi}dBm' : 'BLE';
      case DeviceType.wifi:
        return ipAddress != null ? 'WiFi • $ipAddress' : 'WiFi';
      case DeviceType.usb:
        return 'USB';
    }
  }
}

/// 设备能力
class DeviceCapabilities {
  final bool hasBeanTemp;
  final bool hasAirTemp;
  final bool hasDrumSpeed;
  final bool hasAirflow;
  final bool hasGasControl;
  final bool hasAutoControl;

  DeviceCapabilities({
    this.hasBeanTemp = true,
    this.hasAirTemp = true,
    this.hasDrumSpeed = false,
    this.hasAirflow = false,
    this.hasGasControl = false,
    this.hasAutoControl = false,
  });
}