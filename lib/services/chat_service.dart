import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/conversation_model.dart';
import 'auth_service.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  WebSocketChannel? _webSocketChannel;
  String? _currentAgentId;

  // Stream controller for real-time messages
  final _messageStreamController = StreamController<Conversation>.broadcast();
  Stream<Conversation> get messageStream => _messageStreamController.stream;

  // Get conversation history for an agent
  Future<List<Conversation>> getConversationHistory(String agentId) async {
    try {
      final response = await _supabase
          .from('conversations')
          .select()
          .eq('agent_id', agentId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => Conversation.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting conversation history: $e');
      return [];
    }
  }

  // Send a message to the AI (via Deno server)
  Future<void> sendMessage(
      String agentId, String message, String systemPrompt) async {
    final userId = _authService.getCurrentUser()?.id;

    // Save user message to database
    final userMessage = Conversation(
      id: '',
      agentId: agentId,
      message: message,
      role: 'user',
      createdAt: DateTime.now(),
      userId: userId,
    );

    await _saveMessage(userMessage);
    _messageStreamController.add(userMessage);

    // Send to AI via Deno server
    try {
      // TODO: Replace with your actual Deno server URL if you later use direct WebSocket or HTTP communication.
      final response = await _supabase.functions.invoke(
        'chat',
        body: {
          'agent_id': agentId,
          'message': message,
          'system_prompt': systemPrompt,
          'user_id': userId,
        },
      );

      if (response.data != null) {
        final assistantMessage = Conversation(
          id: '',
          agentId: agentId,
          message:
              response.data['response'] ?? 'Sorry, I could not process that.',
          role: 'assistant',
          createdAt: DateTime.now(),
          userId: userId,
        );

        await _saveMessage(assistantMessage);
        _messageStreamController.add(assistantMessage);
      }
    } catch (e) {
      debugPrint('Error sending message to AI: $e');

      // Add error message
      final errorMessage = Conversation(
        id: '',
        agentId: agentId,
        message: 'Sorry, I encountered an error. Please try again.',
        role: 'assistant',
        createdAt: DateTime.now(),
        userId: userId,
      );

      await _saveMessage(errorMessage);
      _messageStreamController.add(errorMessage);
    }
  }

  // Send message with WebSocket for real-time streaming
  void connectWebSocket(String agentId, String systemPrompt) {
    _currentAgentId = agentId;

    // TODO: Replace with your actual Deno WebSocket URL
    final wsUrl = 'wss://YOUR_DENO_SERVER_URL/ws/chat';

    _webSocketChannel = WebSocketChannel.connect(
      Uri.parse(wsUrl),
    );

    _webSocketChannel!.stream.listen(
      (message) async {
        final data = json.decode(message);
        final userId = _authService.getCurrentUser()?.id;

        final assistantMessage = Conversation(
          id: '',
          agentId: agentId,
          message: data['response'] ?? '',
          role: 'assistant',
          createdAt: DateTime.now(),
          userId: userId,
        );

        await _saveMessage(assistantMessage);
        _messageStreamController.add(assistantMessage);
      },
      onError: (error) {
        debugPrint('WebSocket error: $error');
      },
    );
  }

  void sendWebSocketMessage(String message) {
    if (_webSocketChannel != null) {
      _webSocketChannel!.sink.add(json.encode({
        'message': message,
        'agent_id': _currentAgentId,
      }));
    }
  }

  void disconnectWebSocket() {
    _webSocketChannel?.sink.close();
    _webSocketChannel = null;
    _currentAgentId = null;
  }

  // Save message to Supabase
  Future<void> _saveMessage(Conversation message) async {
    try {
      await _supabase.from('conversations').insert({
        'agent_id': message.agentId,
        'message': message.message,
        'role': message.role,
        'user_id': message.userId,
      });
    } catch (e) {
      debugPrint('Error saving message: $e');
    }
  }

  // Delete conversation history for an agent
  Future<void> deleteConversationHistory(String agentId) async {
    try {
      await _supabase.from('conversations').delete().eq('agent_id', agentId);
    } catch (e) {
      debugPrint('Error deleting conversation history: $e');
      rethrow;
    }
  }

  // Delete a single message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _supabase.from('conversations').delete().eq('id', messageId);
    } catch (e) {
      debugPrint('Error deleting message: $e');
      rethrow;
    }
  }

  // Subscribe to real-time updates for an agent's conversations
  Stream<List<Conversation>> subscribeToConversations(String agentId) {
    return _supabase
        .from('conversations')
        .stream(primaryKey: ['id'])
        .eq('agent_id', agentId)
        .order('created_at', ascending: true)
        .map((data) =>
            (data as List).map((json) => Conversation.fromJson(json)).toList());
  }

  void dispose() {
    _messageStreamController.close();
    disconnectWebSocket();
  }
}
