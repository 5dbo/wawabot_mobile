import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/device_model.dart';
import '../providers/device_provider.dart';
import '../providers/agent_provider.dart';

class DeviceDetailScreen extends StatefulWidget {
  final Device device;

  const DeviceDetailScreen({super.key, required this.device});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  double _currentVolume = 0;
  String? _selectedAgentId;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentVolume = (widget.device.volume ?? 50).toDouble();
    _selectedAgentId = widget.device.currentAgentId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final provider = context.read<DeviceProvider>();
              final messenger = ScaffoldMessenger.of(context);
              await provider.refreshDeviceStatus(widget.device.id);
              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(content: Text('Refreshing device status...')),
              );
            },
          ),
          PopupMenuButton(
            onSelected: (value) {
              if (value == 'unlink') {
                _confirmUnlink();
              } else if (value == 'delete') {
                _confirmDelete();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'unlink',
                child: Row(
                  children: [
                    Icon(Icons.link_off, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Unlink Device'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Device'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.device.isOnline
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.device.isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: widget.device.isOnline
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        const Spacer(),
                        if (widget.device.lastSeen != null)
                          Text(
                            'Last seen: ${_formatDate(widget.device.lastSeen!)}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.settings_ethernet),
                      title: const Text('MAC Address'),
                      subtitle: Text(widget.device.macAddress),
                    ),
                    if (widget.device.deviceCode != null)
                      ListTile(
                        leading: const Icon(Icons.qr_code),
                        title: const Text('Device Code'),
                        subtitle: Text(widget.device.deviceCode!),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Volume Control
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Volume Control',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.volume_down),
                          onPressed: widget.device.isOnline && !_isUpdating
                              ? () => _adjustVolume(_currentVolume - 10)
                              : null,
                        ),
                        Expanded(
                          child: Slider(
                            value: _currentVolume,
                            min: 0,
                            max: 100,
                            divisions: 20,
                            activeColor: widget.device.isOnline
                                ? Colors.blue
                                : Colors.grey,
                            onChanged: widget.device.isOnline && !_isUpdating
                                ? (value) {
                                    setState(() {
                                      _currentVolume = value;
                                    });
                                  }
                                : null,
                            onChangeEnd: widget.device.isOnline && !_isUpdating
                                ? (value) => _updateVolume(value.toInt())
                                : null,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.volume_up),
                          onPressed: widget.device.isOnline && !_isUpdating
                              ? () => _adjustVolume(_currentVolume + 10)
                              : null,
                        ),
                        SizedBox(
                          width: 50,
                          child: Text(
                            '${_currentVolume.toInt()}%',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // AI Agent Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Active AI Agent',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Consumer<AgentProvider>(
                      builder: (context, agentProvider, child) {
                        if (agentProvider.isLoading) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (agentProvider.agents.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.warning,
                                    size: 48, color: Colors.orange),
                                const SizedBox(height: 8),
                                const Text('No agents available'),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                        context, '/create-agent');
                                  },
                                  child: const Text('Create an Agent'),
                                ),
                              ],
                            ),
                          );
                        }

                        return DropdownButtonFormField<String>(
                          value: _selectedAgentId,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('No agent selected'),
                            ),
                            ...agentProvider.agents.map((agent) {
                              return DropdownMenuItem(
                                value: agent.id,
                                child: Text(agent.name),
                              );
                            }),
                          ],
                          onChanged: widget.device.isOnline && !_isUpdating
                              ? (value) {
                                  setState(() {
                                    _selectedAgentId = value;
                                  });
                                  _updateActiveAgent(value);
                                }
                              : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Control Actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Device Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: widget.device.isOnline && !_isUpdating
                                ? () => _sendCommand('reset', null)
                                : null,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: widget.device.isOnline && !_isUpdating
                                ? () => _sendCommand('test', null)
                                : null,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Test'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _adjustVolume(double newVolume) {
    newVolume = newVolume.clamp(0, 100);
    setState(() {
      _currentVolume = newVolume;
    });
    _updateVolume(newVolume.toInt());
  }

  Future<void> _updateVolume(int volume) async {
    setState(() {
      _isUpdating = true;
    });

    final provider = context.read<DeviceProvider>();
    final success = await provider.setVolume(widget.device.id, volume);

    setState(() {
      _isUpdating = false;
    });

    if (!success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to set volume'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateActiveAgent(String? agentId) async {
    if (agentId == null) return;

    setState(() {
      _isUpdating = true;
    });

    final provider = context.read<DeviceProvider>();
    final success = await provider.setActiveAgent(widget.device.id, agentId);

    setState(() {
      _isUpdating = false;
    });

    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to update agent'),
          backgroundColor: Colors.red,
        ),
      );
    } else if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agent updated successfully!')),
      );
    }
  }

  Future<void> _sendCommand(
      String command, Map<String, dynamic>? params) async {
    setState(() {
      _isUpdating = true;
    });

    final provider = context.read<DeviceProvider>();
    final success = await provider.sendCustomCommand(
      widget.device.id,
      command,
      params,
    );

    setState(() {
      _isUpdating = false;
    });

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Command "$command" sent successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to send command'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmUnlink() {
    final stateContext = context;
    showDialog(
      context: stateContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Unlink Device'),
          content:
              Text('Are you sure you want to unlink "${widget.device.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final provider = stateContext.read<DeviceProvider>();
                final navigator = Navigator.of(stateContext);
                final messenger = ScaffoldMessenger.of(stateContext);
                Navigator.pop(dialogContext);
                final success = await provider.unlinkDevice(widget.device.id);
                if (!mounted) return;
                if (success) {
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                        content: Text('Device unlinked successfully')),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                          provider.errorMessage ?? 'Failed to unlink device'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Unlink'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete() {
    final stateContext = context;
    showDialog(
      context: stateContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Device'),
          content: Text(
              'Are you sure you want to permanently delete "${widget.device.name}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final provider = stateContext.read<DeviceProvider>();
                final navigator = Navigator.of(stateContext);
                final messenger = ScaffoldMessenger.of(stateContext);
                Navigator.pop(dialogContext);
                final success = await provider.deleteDevice(widget.device.id);
                if (!mounted) return;
                if (success) {
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                        content: Text('Device deleted successfully')),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                          provider.errorMessage ?? 'Failed to delete device'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
