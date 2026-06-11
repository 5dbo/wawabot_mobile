import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';

class DevicePairingScreen extends StatefulWidget {
  const DevicePairingScreen({super.key});

  @override
  State<DevicePairingScreen> createState() => _DevicePairingScreenState();
}

class _DevicePairingScreenState extends State<DevicePairingScreen> {
  final _macController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isPairing = false;
  
  // For BLE scanning (will be implemented with flutter_blue_plus)
  List<Map<String, String>> _discoveredDevices = [];
  bool _isScanning = false;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pair New Device'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.bluetooth), text: 'Bluetooth'),
              Tab(icon: Icon(Icons.edit), text: 'Manual'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Bluetooth Tab
            _buildBluetoothTab(),
            // Manual Tab
            _buildManualTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildBluetoothTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _isScanning ? null : _startScan,
            icon: _isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
            label: Text(_isScanning ? 'Scanning...' : 'Scan for Devices'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
        Expanded(
          child: _discoveredDevices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bluetooth_disabled,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isScanning ? 'Searching for devices...' : 'No devices found',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      if (!_isScanning) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Make sure your ElatoAI device is in pairing mode',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _discoveredDevices.length,
                  itemBuilder: (context, index) {
                    final device = _discoveredDevices[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.devices, size: 32),
                        title: Text(device['name'] ?? 'Unknown Device'),
                        subtitle: Text(device['address'] ?? ''),
                        trailing: ElevatedButton(
                          onPressed: () => _connectToDevice(device['address']!),
                          child: const Text('Connect'),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildManualTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manual Device Pairing',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the device information manually to pair with your ElatoAI device.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _macController,
            decoration: const InputDecoration(
              labelText: 'MAC Address *',
              hintText: 'XX:XX:XX:XX:XX:XX',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.settings_ethernet),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Device Code *',
              hintText: 'Enter 6-digit pairing code',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.qr_code),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isPairing ? null : _pairManually,
              icon: _isPairing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.link),
              label: Text(_isPairing ? 'Pairing...' : 'Pair Device'),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Where to find this information?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '1. MAC Address: Found on the device label or in the device settings\n'
                  '2. Device Code: Displayed on the device screen or in the setup wizard',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _discoveredDevices.clear();
    });
    
    // TODO: Implement BLE scanning with flutter_blue_plus
    // This is a placeholder - you'll need to add the actual BLE implementation
    await Future.delayed(const Duration(seconds: 3));
    
    // Mock discovered devices (replace with actual BLE scan results)
    setState(() {
      _discoveredDevices = [
        {'name': 'ELATO-DEVICE-001', 'address': 'AA:BB:CC:DD:EE:FF'},
        {'name': 'ELATO-DEVICE-002', 'address': '11:22:33:44:55:66'},
      ];
      _isScanning = false;
    });
  }

  Future<void> _connectToDevice(String address) async {
    // TODO: Implement connection to BLE device
    // This would typically open a dialog to enter the device code
    _showDeviceCodeDialog(address);
  }

  void _showDeviceCodeDialog(String macAddress) {
    final codeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Device Code'),
          content: TextField(
            controller: codeController,
            decoration: const InputDecoration(
              labelText: '6-digit Code',
              hintText: 'Enter the code displayed on your device',
            ),
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _pairDevice(macAddress, codeController.text);
              },
              child: const Text('Pair'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pairManually() async {
    if (_macController.text.isEmpty || _codeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both MAC Address and Device Code'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    await _pairDevice(_macController.text, _codeController.text);
  }

  Future<void> _pairDevice(String macAddress, String deviceCode) async {
    setState(() {
      _isPairing = true;
    });
    
    final success = await context.read<DeviceProvider>().pairDevice(
      macAddress,
      deviceCode,
    );
    
    setState(() {
      _isPairing = false;
    });
    
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device paired successfully!')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<DeviceProvider>().errorMessage ?? 'Pairing failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _macController.dispose();
    _codeController.dispose();
    super.dispose();
  }
}