import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/agent_model.dart';
import '../models/conversation_model.dart';
import '../providers/chat_provider.dart';
import '../widgets/conversation_bubble.dart';

class ChatScreen extends StatefulWidget {
  final Agent agent;

  const ChatScreen({super.key, required this.agent});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadConversationHistory(widget.agent);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();
    context.read<ChatProvider>().sendMessage(message);

    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.agent.name),
            const SizedBox(height: 2),
            Text(
              'AI Assistant',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade300,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearConversation,
            tooltip: 'Clear conversation',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showAgentInfo,
            tooltip: 'Agent info',
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                if (chatProvider.isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading conversation...'),
                      ],
                    ),
                  );
                }

                if (chatProvider.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start a conversation with ${widget.agent.name}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your AI assistant is ready to chat!',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    return ConversationBubble(
                      message: message,
                      onLongPress: () {
                        _showMessageOptions(context, message, index);
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Typing indicator
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              if (!chatProvider.isSending) return const SizedBox.shrink();

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.agent.name} is typing...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(0, 0, 0, 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Message ${widget.agent.name}...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.attach_file),
                        onPressed: _showAttachOptions,
                        tooltip: 'Attach',
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    return CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.blue,
                      child: IconButton(
                        icon: Icon(
                          chatProvider.isSending ? Icons.stop : Icons.send,
                          color: Colors.white,
                        ),
                        onPressed: chatProvider.isSending ? null : _sendMessage,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _clearConversation() {
    final stateContext = context;
    showDialog(
      context: stateContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear Conversation'),
          content: Text(
            'Are you sure you want to clear all messages with ${widget.agent.name}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final provider = stateContext.read<ChatProvider>();
                final messenger = ScaffoldMessenger.of(stateContext);
                Navigator.pop(dialogContext);
                await provider.clearConversationHistory();
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(content: Text('Conversation cleared')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  void _showAgentInfo() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(widget.agent.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(widget.agent.description),
              const SizedBox(height: 16),
              const Text(
                'System Prompt',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.agent.systemPrompt,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              if (widget.agent.voiceId != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Voice ID',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(widget.agent.voiceId!),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showMessageOptions(
      BuildContext context, Conversation message, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy Message'),
                onTap: () {
                  Navigator.pop(context);
                  _copyToClipboard(message.message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Message'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, message.id, index);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _copyToClipboard(String text) {
    // TODO: Implement clipboard copy
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message copied to clipboard')),
    );
  }

  void _confirmDelete(BuildContext context, String messageId, int index) {
    final stateContext = context;
    showDialog(
      context: stateContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Message'),
          content: const Text('Are you sure you want to delete this message?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final provider = stateContext.read<ChatProvider>();
                final messenger = ScaffoldMessenger.of(stateContext);
                Navigator.pop(dialogContext);
                await provider.deleteMessage(messageId, index);
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(content: Text('Message deleted')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showAttachOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Send Image'),
                onTap: () {
                  Navigator.pop(context);
                  _sendImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.mic),
                title: const Text('Send Voice Message'),
                onTap: () {
                  Navigator.pop(context);
                  _sendVoiceMessage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendImage() {
    // TODO: Implement image sending
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image sending coming soon')),
    );
  }

  void _sendVoiceMessage() {
    // TODO: Implement voice message sending
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice messaging coming soon')),
    );
  }
}
