import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/agent_provider.dart';
import '../widgets/agent_card.dart';
import 'agent_create_screen.dart';
import 'agent_detail_screen.dart';

class AgentsScreen extends StatefulWidget {
  const AgentsScreen({super.key});

  @override
  State<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends State<AgentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AgentProvider>().loadAgents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AgentProvider>(
        builder: (context, agentProvider, child) {
          if (agentProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (agentProvider.agents.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.android, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No AI Agents Yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Tap the + button to create your first agent'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: agentProvider.agents.length,
            itemBuilder: (context, index) {
              final agent = agentProvider.agents[index];
              return AgentCard(
                agent: agent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AgentDetailScreen(agent: agent),
                    ),
                  );
                },
              );
            },
          );
        },
      ),

      // Add this to the agents_screen.dart file (update the floatingActionButton)

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AgentCreateScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
