import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/agent_model.dart';
import '../models/conversation_model.dart';
import 'conversation_bubble.dart';

class ConversationHistory extends StatefulWidget {
  final Agent agent;

  const ConversationHistory({super.key, required this.agent});

  @override
  State<ConversationHistory> createState() => _ConversationHistoryState();
}

class _ConversationHistoryState extends State<ConversationHistory> {
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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (chatProvider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading conversation history...'),
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
                  'No messages yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start a conversation with ${widget.agent.name}',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

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
              if (message.isUserMessage)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Message'),
                  onTap: () {
                    Navigator.pop(context);
                    _editMessage(context, message);
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

  void _editMessage(BuildContext context, Conversation message) {
    // TODO: Implement message editing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message editing coming soon')),
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
}
