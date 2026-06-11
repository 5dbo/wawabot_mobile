import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/agent_model.dart';
import '../models/conversation_model.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Agents
  Future<List<Agent>> getAgents(String userId) async {
    final response = await _supabase
        .from('agents')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((json) => Agent.fromJson(json))
        .toList();
  }

  Future<void> createAgent(Agent agent) async {
    await _supabase
        .from('agents')
        .insert(agent.toJson());
  }

  Future<void> updateAgent(String id, Map<String, dynamic> data) async {
    await _supabase
        .from('agents')
        .update(data)
        .eq('id', id);
  }

  Future<void> deleteAgent(String id) async {
    await _supabase
        .from('agents')
        .delete()
        .eq('id', id);
  }

  // Conversations
  Stream<List<Conversation>> getConversations(String agentId) {
    return _supabase
        .from('conversations')
        .stream(primaryKey: ['id'])
        .eq('agent_id', agentId)
        .order('created_at', ascending: true)
        .map((data) => (data as List)
            .map((json) => Conversation.fromJson(json))
            .toList());
  }

  Future<void> sendMessage(String agentId, String message, String role) async {
    await _supabase
        .from('conversations')
        .insert({
          'agent_id': agentId,
          'message': message,
          'role': role,
        });
  }
}