import 'dart:async';

import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../services/device_service.dart';
import '../services/auth_service.dart';

class DeviceProvider extends ChangeNotifier {
  final DeviceService _deviceService = DeviceService();
  final AuthService _authService = AuthService();

  List<Device> _devices = [];
  bool _isLoading = false;
  bool _isPairing = false;
  String? _errorMessage;
  Device? _selectedDevice;

  // Stream subscriptions
  final Map<String, StreamSubscription<Device>> _deviceSubscriptions = {};

  List<Device> get devices => _devices;
  bool get isLoading => _isLoading;
  bool get isPairing => _isPairing;
  String? get errorMessage => _errorMessage;
  Device? get selectedDevice => _selectedDevice;

  List<Device> get onlineDevices => _devices.where((d) => d.isOnline).toList();
  List<Device> get offlineDevices =>
      _devices.where((d) => !d.isOnline).toList();

  // Load all devices for current user
  Future<void> loadDevices() async {
    final userId = _authService.getCurrentUser()?.id;
    if (userId == null) {
      _errorMessage = 'User not authenticated';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _devices = await _deviceService.getUserDevices(userId);
      // Setup real-time listeners for each device
      for (var device in _devices) {
        _subscribeToDeviceStatus(device.id);
      }
    } catch (e) {
      _errorMessage = 'Failed to load devices: $e';
      debugPrint('Error loading devices: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Subscribe to real-time updates for a device
  void _subscribeToDeviceStatus(String deviceId) {
    if (_deviceSubscriptions.containsKey(deviceId)) return;

    final subscription = _deviceService
        .subscribeToDeviceStatus(deviceId)
        .listen((updatedDevice) {
      final index = _devices.indexWhere((d) => d.id == updatedDevice.id);
      if (index != -1) {
        _devices[index] = updatedDevice;
        if (_selectedDevice?.id == updatedDevice.id) {
          _selectedDevice = updatedDevice;
        }
        notifyListeners();
      }
    });

    _deviceSubscriptions[deviceId] = subscription;
  }

  // Pair/link a new device
  Future<bool> pairDevice(String macAddress, String deviceCode) async {
    final userId = _authService.getCurrentUser()?.id;
    if (userId == null) {
      _errorMessage = 'User not authenticated';
      notifyListeners();
      return false;
    }

    _isPairing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _deviceService.linkDevice(userId, macAddress, deviceCode);
      await loadDevices(); // Refresh device list
      return true;
    } catch (e) {
      _errorMessage = 'Failed to pair device: $e';
      debugPrint('Error pairing device: $e');
      return false;
    } finally {
      _isPairing = false;
      notifyListeners();
    }
  }

  // Unlink device
  Future<bool> unlinkDevice(String deviceId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _deviceService.unlinkDevice(deviceId);

      // Cancel subscription
      _deviceSubscriptions[deviceId]?.cancel();
      _deviceSubscriptions.remove(deviceId);

      await loadDevices(); // Refresh device list
      return true;
    } catch (e) {
      _errorMessage = 'Failed to unlink device: $e';
      debugPrint('Error unlinking device: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete device permanently
  Future<bool> deleteDevice(String deviceId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _deviceService.deleteDevice(deviceId);

      // Cancel subscription
      _deviceSubscriptions[deviceId]?.cancel();
      _deviceSubscriptions.remove(deviceId);

      await loadDevices(); // Refresh device list
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete device: $e';
      debugPrint('Error deleting device: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set active AI agent for device
  Future<bool> setActiveAgent(String deviceId, String agentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _deviceService.setActiveAgent(deviceId, agentId);

      // Find device and send command if online
      final device = _devices.firstWhere((d) => d.id == deviceId);
      if (device.isOnline && device.macAddress.isNotEmpty) {
        await _deviceService.sendCommandToDevice(
          device.macAddress,
          'set_agent',
          {'agent_id': agentId},
        );
      }

      return true;
    } catch (e) {
      _errorMessage = 'Failed to set active agent: $e';
      debugPrint('Error setting active agent: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set device volume
  Future<bool> setVolume(String deviceId, int volume) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _deviceService.setVolume(deviceId, volume);

      // Find device and send command if online
      final device = _devices.firstWhere((d) => d.id == deviceId);
      if (device.isOnline && device.macAddress.isNotEmpty) {
        await _deviceService.sendCommandToDevice(
          device.macAddress,
          'set_volume',
          {'volume': volume},
        );
      }

      return true;
    } catch (e) {
      _errorMessage = 'Failed to set volume: $e';
      debugPrint('Error setting volume: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send custom command to device
  Future<bool> sendCustomCommand(
      String deviceId, String command, Map<String, dynamic>? params) async {
    try {
      final device = _devices.firstWhere((d) => d.id == deviceId);
      if (!device.isOnline) {
        _errorMessage = 'Device is offline';
        notifyListeners();
        return false;
      }

      await _deviceService.sendCommandToDevice(
          device.macAddress, command, params);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to send command: $e';
      debugPrint('Error sending command: $e');
      return false;
    } finally {
      notifyListeners();
    }
  }

  // Select device for detail view
  void selectDevice(Device device) {
    _selectedDevice = device;
    notifyListeners();
  }

  // Clear selected device
  void clearSelectedDevice() {
    _selectedDevice = null;
    notifyListeners();
  }

  // Get device by ID
  Device? getDeviceById(String id) {
    try {
      return _devices.firstWhere((device) => device.id == id);
    } catch (e) {
      return null;
    }
  }

  // Refresh device status manually
  Future<void> refreshDeviceStatus(String deviceId) async {
    final device = getDeviceById(deviceId);
    if (device != null && device.macAddress.isNotEmpty) {
      try {
        await _deviceService.sendCommandToDevice(
          device.macAddress,
          'status',
          null,
        );
      } catch (e) {
        debugPrint('Error refreshing device status: $e');
      }
    }
  }

  @override
  void dispose() {
    // Cancel all real-time subscriptions
    for (var subscription in _deviceSubscriptions.values) {
      subscription.cancel();
    }
    _deviceSubscriptions.clear();
    super.dispose();
  }
}
