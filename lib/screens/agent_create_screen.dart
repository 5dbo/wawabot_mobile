import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/agent_provider.dart';

class AgentCreateScreen extends StatefulWidget {
  const AgentCreateScreen({super.key});

  @override
  State<AgentCreateScreen> createState() => _AgentCreateScreenState();
}

class _AgentCreateScreenState extends State<AgentCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _systemPromptController = TextEditingController();
  final _voiceIdController = TextEditingController();
  bool _isCreating = false;

  // Example system prompts
  final List<Map<String, String>> _promptExamples = [
    {
      'name': 'Friendly Assistant',
      'prompt': 'You are a friendly and helpful AI assistant. You speak warmly and enthusiastically. You love to help users with their questions and always maintain a positive attitude.'
    },
    {
      'name': 'Storyteller',
      'prompt': 'You are a creative storyteller. You tell engaging stories with vivid descriptions and interesting characters. You adapt your stories based on the user\'s interests.'
    },
    {
      'name': 'Teacher',
      'prompt': 'You are a patient and knowledgeable teacher. You explain concepts clearly and check for understanding. You encourage curiosity and provide examples to illustrate ideas.'
    },
  ];

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
        title: const Text('Create New Agent'),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createAgent,
            child: const Text('Create'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              const Text(
                'Basic Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Agent Name *',
                  hintText: 'e.g., My Friendly Bot',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an agent name';
                  }
                  if (value.length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  hintText: 'What is this agent\'s personality and purpose?',
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
              const SizedBox(height: 24),

              // System Prompt
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'System Prompt *',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.lightbulb_outline),
                    tooltip: 'Show examples',
                    onSelected: (Map<String, String> example) {
                      setState(() {
                        _systemPromptController.text = example['prompt']!;
                      });
                    },
                    itemBuilder: (context) {
                      return _promptExamples.map((example) {
                        return PopupMenuItem(
                          value: example,
                          child: Text(example['name']!),
                        );
                      }).toList();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'The system prompt defines your agent\'s personality, behavior, and how it responds to users.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _systemPromptController,
                decoration: const InputDecoration(
                  labelText: 'System Prompt',
                  hintText: 'You are a helpful AI assistant that...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.code),
                  alignLabelWithHint: true,
                ),
                maxLines: 8,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a system prompt';
                  }
                  if (value.length < 20) {
                    return 'System prompt should be more detailed (min 20 characters)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Voice Settings (Optional)
              const Text(
                'Voice Settings (Optional)',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'You can assign a voice ID later. Voice integration requires additional setup.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _voiceIdController,
                decoration: const InputDecoration(
                  labelText: 'Voice ID',
                  hintText: 'Enter voice ID if you have one',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.record_voice_over),
                ),
              ),

              const SizedBox(height: 32),

              // Create Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isCreating ? null : _createAgent,
                  icon: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(_isCreating ? 'Creating...' : 'Create Agent'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createAgent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    final success = await context.read<AgentProvider>().createAgent(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      systemPrompt: _systemPromptController.text.trim(),
      voiceId: _voiceIdController.text.isNotEmpty ? _voiceIdController.text.trim() : null,
    );

    setState(() {
      _isCreating = false;
    });

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agent created successfully!')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<AgentProvider>().errorMessage ?? 'Failed to create agent'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}