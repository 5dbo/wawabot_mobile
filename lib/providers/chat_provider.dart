import 'package:flutter/material.dart';
import '../models/conversation_model.dart';
import '../models/agent_model.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<Conversation> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;
  Agent? _currentAgent;
  String? _currentAgentSystemPrompt;

  List<Conversation> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;
  Agent? get currentAgent => _currentAgent;

  ChatProvider() {
    // Listen to real-time messages
    _chatService.messageStream.listen((message) {
      _messages.add(message);
      notifyListeners();
    });
  }

  // Load conversation history for an agent
  Future<void> loadConversationHistory(Agent agent) async {
    _currentAgent = agent;
    _currentAgentSystemPrompt = agent.systemPrompt;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _messages = await _chatService.getConversationHistory(agent.id);
    } catch (e) {
      _errorMessage = 'Failed to load conversation history: $e';
      debugPrint('Error loading conversation history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send a new message
  Future<void> sendMessage(String message) async {
    if (_currentAgent == null) {
      _errorMessage = 'No agent selected';
      notifyListeners();
      return;
    }

    if (message.trim().isEmpty) {
      return;
    }

    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _chatService.sendMessage(
        _currentAgent!.id,
        message.trim(),
        _currentAgentSystemPrompt ?? _currentAgent!.systemPrompt,
      );
    } catch (e) {
      _errorMessage = 'Failed to send message: $e';
      debugPrint('Error sending message: $e');

      // Add error message to chat
      final errorMessage = Conversation(
        id: '',
        agentId: _currentAgent!.id,
        message: 'Failed to send message. Please check your connection.',
        role: 'assistant',
        createdAt: DateTime.now(),
      );
      _messages.add(errorMessage);
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  // Clear all messages for current agent
  Future<void> clearConversationHistory() async {
    if (_currentAgent == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _chatService.deleteConversationHistory(_currentAgent!.id);
      _messages.clear();
    } catch (e) {
      _errorMessage = 'Failed to clear conversation: $e';
      debugPrint('Error clearing conversation: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a specific message
  Future<void> deleteMessage(String messageId, int index) async {
    try {
      await _chatService.deleteMessage(messageId);
      _messages.removeAt(index);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete message: $e';
      debugPrint('Error deleting message: $e');
      notifyListeners();
    }
  }

  // Reset provider state
  void reset() {
    _messages.clear();
    _currentAgent = null;
    _isLoading = false;
    _isSending = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _chatService.dispose();
    super.dispose();
  }
}
