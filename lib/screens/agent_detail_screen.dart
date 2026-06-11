import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/agent_model.dart';
import '../providers/agent_provider.dart';
import '../widgets/conversation_history.dart';

class AgentDetailScreen extends StatefulWidget {
  final Agent agent;

  const AgentDetailScreen({super.key, required this.agent});

  @override
  State<AgentDetailScreen> createState() => _AgentDetailScreenState();
}

class _AgentDetailScreenState extends State<AgentDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late Agent _agent;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _systemPromptController;
  late TextEditingController _voiceIdController;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _agent = widget.agent;
    _nameController = TextEditingController(text: _agent.name);
    _descriptionController = TextEditingController(text: _agent.description);
    _systemPromptController = TextEditingController(text: _agent.systemPrompt);
    _voiceIdController = TextEditingController(text: _agent.voiceId ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _systemPromptController.dispose();
    _voiceIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Agent' : widget.agent.name),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
            ),
          if (_isEditing)
            TextButton(
              onPressed: _isSaving ? null : _saveChanges,
              child: const Text('Save'),
            ),
          if (_isEditing)
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _resetControllers();
                });
              },
              child: const Text('Cancel'),
            ),
        ],
      ),
      body: _isEditing ? _buildEditForm() : _buildViewMode(),
    );
  }

  Widget _buildViewMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar and basic info
          Center(
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.android, size: 60),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.agent.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.agent.description,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // System Prompt
          const Text(
            'System Prompt',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              widget.agent.systemPrompt,
              style: const TextStyle(height: 1.5),
            ),
          ),
          const SizedBox(height: 16),

          // Voice ID
          if (widget.agent.voiceId != null) ...[
            const Text(
              'Voice ID',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(widget.agent.voiceId!),
            ),
          ],

          const SizedBox(height: 24),

          // Conversation History
          const Text(
            'Conversation History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ConversationHistory(agent: _agent),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Agent Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an agent name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _systemPromptController,
              decoration: const InputDecoration(
                labelText: 'System Prompt',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.code),
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a system prompt';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _voiceIdController,
              decoration: const InputDecoration(
                labelText: 'Voice ID (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.record_voice_over),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetControllers() {
    _nameController.text = _agent.name;
    _descriptionController.text = _agent.description;
    _systemPromptController.text = _agent.systemPrompt;
    _voiceIdController.text = _agent.voiceId ?? '';
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final provider = context.read<AgentProvider>();
    final success = await provider.updateAgent(
      agentId: widget.agent.id,
      name: _nameController.text,
      description: _descriptionController.text,
      systemPrompt: _systemPromptController.text,
      voiceId:
          _voiceIdController.text.isNotEmpty ? _voiceIdController.text : null,
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agent updated successfully!')),
      );
      setState(() {
        _isEditing = false;
        _agent = Agent(
          id: _agent.id,
          name: _nameController.text,
          description: _descriptionController.text,
          systemPrompt: _systemPromptController.text,
          voiceId: _voiceIdController.text.isNotEmpty
              ? _voiceIdController.text
              : null,
          avatarUrl: _agent.avatarUrl,
          createdAt: _agent.createdAt,
          userId: _agent.userId,
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to update agent'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmDelete() {
    final stateContext = context;
    showDialog(
      context: stateContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Agent'),
          content: Text(
              'Are you sure you want to delete "${widget.agent.name}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final provider = stateContext.read<AgentProvider>();
                Navigator.pop(dialogContext);
                final navigator = Navigator.of(stateContext);
                final messenger = ScaffoldMessenger.of(stateContext);
                final success = await provider.deleteAgent(widget.agent.id);
                if (!mounted) return;
                if (success) {
                  navigator.pop(); // Return to agents list
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Agent deleted successfully')),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                          provider.errorMessage ?? 'Failed to delete agent'),
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
}
