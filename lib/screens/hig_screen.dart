import 'package:flutter/material.dart';
import 'package:localiza_agendamentos/screens/login_screen.dart';
import '../core/firebase_service.dart';
import '../core/notification_service.dart';

class HigScreen extends StatefulWidget {
  final String nome;
  final String tokenDevice;

  const HigScreen({
    super.key,
    required this.nome,
    required this.tokenDevice,
  });

  @override
  State<HigScreen> createState() => _HigScreenState();
}

class _HigScreenState extends State<HigScreen> {
  final _firebaseService = FirebaseService();
  final Set<String> _notifiedAgendamentos = {}; // para não notificar repetidamente

  Future<void> _concluirAgendamento(String id) async {
    await _firebaseService.atualizarStatus(id, 'concluído');
    NotificationService.show(
      'Higienização concluída',
      'Agendamento finalizado com sucesso.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Higienizador: ${widget.nome}'),
        backgroundColor: const Color.fromRGBO(8, 143, 66, 1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          )
        ],
      ),
      body: StreamBuilder(
        stream: _firebaseService.listarAgendamentos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          // Filtra apenas agendamentos pendentes e do seu token
          final meusAgendamentos = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['status'] ?? '').toLowerCase() == 'pendente';
          }).toList();

          // Dispara notificação para novos agendamentos
          for (var doc in meusAgendamentos) {
            if (!_notifiedAgendamentos.contains(doc.id)) {
              final data = doc.data() as Map<String, dynamic>;
              NotificationService.show(
                'Novo agendamento',
                'Modelo: ${data['modelo']}, Placa: ${data['placa']}',
              );
              _notifiedAgendamentos.add(doc.id);
            }
          }

          if (meusAgendamentos.isEmpty) {
            return const Center(child: Text('Nenhum agendamento pendente.'));
          }

          return ListView.builder(
            itemCount: meusAgendamentos.length,
            itemBuilder: (context, index) {
              final doc = meusAgendamentos[index];
              final data = doc.data() as Map<String, dynamic>;

              return ListTile(
                title: Text('${data['modelo']} - ${data['placa']}'),
                subtitle: Text('Consultor: ${data['vendedor']}'),
                trailing: ElevatedButton(
                  onPressed: () => _concluirAgendamento(doc.id),
                  child: const Text('Concluir'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
