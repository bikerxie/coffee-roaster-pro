import 'package:flutter/material.dart';

/// 设备连接界面
/// 用于扫描和连接蓝牙/WiFi咖啡烘焙机设备
class DeviceConnectionScreen extends StatefulWidget {
  const DeviceConnectionScreen({super.key});

  @override
  State<DeviceConnectionScreen> createState() => _DeviceConnectionScreenState();
}

class _DeviceConnectionScreenState extends State<DeviceConnectionScreen> {
  bool _isScanning = false;
  Device? _connectedDevice;
  List<Device> _devices = [];

  final Color _backgroundColor = const Color(0xFF1A1A1A);
  final Color _cardColor = const Color(0xFF2D2D2D);
  final Color _accentColor = const Color(0xFFE67E22);
  final Color _textColor = Colors.white;
  final Color _secondaryTextColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
    });
    
    // 模拟扫描过程
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _devices = _getMockDevices();
          _isScanning = false;
        });
      }
    });
  }

  List<Device> _getMockDevices() {
    return [
      Device(
        id: '1',
        name: 'Coffee Roaster Pro',
        type: DeviceType.wifi,
        signalStrength: 85,
        isConnected: false,
      ),
      Device(
        id: '2',
        name: 'RoastMaster X1',
        type: DeviceType.bluetooth,
        signalStrength: 72,
        isConnected: false,
      ),
      Device(
        id: '3',
        name: 'Smart Roaster',
        type: DeviceType.wifi,
        signalStrength: 60,
        isConnected: false,
      ),
      Device(
        id: '4',
        name: 'Home Roast BT',
        type: DeviceType.bluetooth,
        signalStrength: 45,
        isConnected: false,
      ),
    ];
  }

  void _connectDevice(Device device) {
    setState(() {
      if (_connectedDevice != null) {
        _connectedDevice!.isConnected = false;
      }
      device.isConnected = true;
      _connectedDevice = device;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已连接到 ${device.name}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _disconnectDevice(Device device) {
    setState(() {
      device.isConnected = false;
      _connectedDevice = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已断开连接'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSignalIndicator(int strength) {
    Color color;
    if (strength >= 70) {
      color = Colors.green;
    } else if (strength >= 40) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.signal_cellular_alt, color: color, size: 18),
        const SizedBox(width: 4),
        Text(
          '$strength%',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceTypeIcon(DeviceType type) {
    IconData iconData;
    String label;
    Color color;
    
    switch (type) {
      case DeviceType.wifi:
        iconData = Icons.wifi;
        label = 'WiFi';
        color = const Color(0xFF3498DB);
        break;
      case DeviceType.bluetooth:
        iconData = Icons.bluetooth;
        label = '蓝牙';
        color = const Color(0xFF9B59B6);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        elevation: 0,
        title: Text(
          '设备连接',
          style: TextStyle(color: _textColor),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.refresh, color: _textColor),
            onPressed: _isScanning ? null : _startScan,
          ),
        ],
      ),
      body: Column(
        children: [
          // 扫描状态提示
          if (_isScanning)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: _accentColor.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '正在扫描附近设备...',
                    style: TextStyle(
                      color: _accentColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          
          // 已连接设备指示器
          if (_connectedDevice != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '已连接',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _connectedDevice!.name,
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDeviceTypeIcon(_connectedDevice!.type),
                ],
              ),
            ),
          
          // 设备列表
          Expanded(
            child: _devices.isEmpty && !_isScanning
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_searching,
                          size: 64,
                          color: _secondaryTextColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '未发现设备',
                          style: TextStyle(
                            color: _secondaryTextColor,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _startScan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('重新扫描'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      return _buildDeviceCard(device);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(Device device) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: device.isConnected
            ? Border.all(color: Colors.green.withOpacity(0.5), width: 2)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.coffee_maker,
                    color: _accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildDeviceTypeIcon(device.type),
                          const SizedBox(width: 12),
                          _buildSignalIndicator(device.signalStrength),
                        ],
                      ),
                    ],
                  ),
                ),
                if (device.isConnected)
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green,
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: device.isConnected
                        ? () => _disconnectDevice(device)
                        : () => _connectDevice(device),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: device.isConnected
                          ? Colors.red.withOpacity(0.8)
                          : _accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      device.isConnected ? '断开连接' : '连接设备',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum DeviceType {
  wifi,
  bluetooth,
}

class Device {
  final String id;
  final String name;
  final DeviceType type;
  final int signalStrength;
  bool isConnected;

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.signalStrength,
    this.isConnected = false,
  });
}
