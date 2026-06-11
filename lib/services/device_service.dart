import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/device_model.dart';

class DeviceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Supabase operations
  Future<List<Device>> getUserDevices(String userId) async {
    final response = await _supabase
        .from('devices')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Device.fromJson(json)).toList();
  }

  Future<void> linkDevice(
      String userId, String macAddress, String deviceCode) async {
    // Check if device exists
    final existingDevice = await _supabase
        .from('devices')
        .select()
        .eq('mac_address', macAddress)
        .maybeSingle();

    if (existingDevice != null) {
      // Update existing device with user
      await _supabase
          .from('devices')
          .update({'user_id': userId, 'device_code': deviceCode}).eq(
              'mac_address', macAddress);
    } else {
      // Create new device
      await _supabase.from('devices').insert({
        'name': 'ElatoAI Device',
        'mac_address': macAddress,
        'device_code': deviceCode,
        'user_id': userId,
        'is_online': false,
      });
    }
  }

  Future<void> unlinkDevice(String deviceId) async {
    await _supabase
        .from('devices')
        .update({'user_id': null}).eq('id', deviceId);
  }

  Future<void> updateDevice(
      String deviceId, Map<String, dynamic> updates) async {
    await _supabase.from('devices').update(updates).eq('id', deviceId);
  }

  Future<void> deleteDevice(String deviceId) async {
    await _supabase.from('devices').delete().eq('id', deviceId);
  }

  Future<void> setActiveAgent(String deviceId, String agentId) async {
    await updateDevice(deviceId, {'current_agent_id': agentId});
  }

  Future<void> setVolume(String deviceId, int volume) async {
    await updateDevice(deviceId, {'volume': volume.clamp(0, 100)});
  }

  // Real-time subscription for device status
  Stream<Device> subscribeToDeviceStatus(String deviceId) {
    return _supabase
        .from('devices')
        .stream(primaryKey: ['id'])
        .eq('id', deviceId)
        .map((event) => Device.fromJson(event.first));
  }

  // WebSocket command to Deno server for controlling device
  Future<void> sendCommandToDevice(String deviceMacAddress, String command,
      Map<String, dynamic>? params) async {
    // TODO: Replace with your actual Deno server URL
    final denoServerUrl = 'YOUR_DENO_SERVER_URL';

    try {
      final response = await http.post(
        Uri.parse('$denoServerUrl/api/command'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'mac_address': deviceMacAddress,
          'command': command,
          'parameters': params ?? {},
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send command: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error sending command: $e');
      rethrow;
    }
  }
}
