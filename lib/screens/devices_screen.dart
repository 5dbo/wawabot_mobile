import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/device_model.dart';
import '../providers/device_provider.dart';
import '../widgets/device_card.dart';
import 'device_pairing_screen.dart';
import 'device_detail_screen.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceProvider>().loadDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<DeviceProvider>().loadDevices();
        },
        child: Consumer<DeviceProvider>(
          builder: (context, deviceProvider, child) {
            if (deviceProvider.isLoading && deviceProvider.devices.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (deviceProvider.devices.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.devices,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Devices Connected',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the + button to pair a new device',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        _showPairingOptions(context);
                      },
                      icon: const Icon(Icons.bluetooth),
                      label: const Text('Pair New Device'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Online devices section
                if (deviceProvider.onlineDevices.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 8),
                    child: Text(
                      'Online',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  ...deviceProvider.onlineDevices.map((device) => DeviceCard(
                        device: device,
                        onTap: () {
                          _navigateToDeviceDetail(device);
                        },
                      )),
                  const SizedBox(height: 16),
                ],

                // Offline devices section
                if (deviceProvider.offlineDevices.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 8),
                    child: Text(
                      'Offline',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  ...deviceProvider.offlineDevices.map((device) => DeviceCard(
                        device: device,
                        onTap: () {
                          _navigateToDeviceDetail(device);
                        },
                      )),
                ],
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showPairingOptions(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showPairingOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.bluetooth, size: 32),
                title: const Text('Pair via Bluetooth'),
                subtitle: const Text('Discover and pair with nearby devices'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToPairing();
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner, size: 32),
                title: const Text('Scan QR Code'),
                subtitle: const Text('Scan device QR code to pair'),
                onTap: () {
                  Navigator.pop(context);
                  _showQRScanner(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.code, size: 32),
                title: const Text('Enter Device Code'),
                subtitle: const Text('Manually enter the device pairing code'),
                onTap: () {
                  Navigator.pop(context);
                  _showManualPairingDialog(context);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _navigateToPairing() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DevicePairingScreen()),
    );
  }

  void _navigateToDeviceDetail(Device device) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeviceDetailScreen(device: device),
      ),
    );
  }

  void _showQRScanner(BuildContext context) {
    // TODO: Implement QR code scanner
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR Scanner coming soon!')),
    );
  }

  void _showManualPairingDialog(BuildContext context) {
    final macController = TextEditingController();
    final codeController = TextEditingController();

    final stateContext = context;
    showDialog(
      context: stateContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Manual Device Pairing'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: macController,
                decoration: const InputDecoration(
                  labelText: 'MAC Address',
                  hintText: 'XX:XX:XX:XX:XX:XX',
                  prefixIcon: Icon(Icons.settings_ethernet),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Device Code',
                  hintText: 'Enter 6-digit code',
                  prefixIcon: Icon(Icons.qr_code),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (macController.text.isNotEmpty &&
                    codeController.text.isNotEmpty) {
                  final provider = stateContext.read<DeviceProvider>();
                  final messenger = ScaffoldMessenger.of(stateContext);
                  final navigator = Navigator.of(stateContext);
                  final success = await provider.pairDevice(
                    macController.text,
                    codeController.text,
                  );
                  navigator.pop();
                  if (!mounted) return;
                  if (success) {
                    messenger.showSnackBar(
                      const SnackBar(
                          content: Text('Device paired successfully!')),
                    );
                  } else {
                    messenger.showSnackBar(
                      SnackBar(
                        content:
                            Text(provider.errorMessage ?? 'Pairing failed'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Pair Device'),
            ),
          ],
        );
      },
    );
  }
}
