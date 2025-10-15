

import 'package:flutter/material.dart';
import 'package:localiza_agendamentos/screens/login_screen.dart';
import '../core/firebase_service.dart';
import '../widgets/agendamento_form.dart';

class HomeScreen extends StatelessWidget {
  final String nomeVendedor;
  final String tokenDevice;
  final _firebaseService = FirebaseService();

  HomeScreen({
    super.key,
    required this.nomeVendedor,
    required this.tokenDevice,
  });

  void _novoAgendamento(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AgendamentoForm(
        nomeVendedor: nomeVendedor,
        tokenDevice: tokenDevice,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, $nomeVendedor'),
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

          // Filtra apenas agendamentos do usuário logado
          final meusAgendamentos = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['vendedor'] == nomeVendedor; // ou data['tokenId'] == tokenDevice
          }).toList();

          if (meusAgendamentos.isEmpty) {
            return const Center(
              child: Text('Você não possui agendamentos.'),
            );
          }

          return ListView(
            children: meusAgendamentos.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text('${data['modelo']} - ${data['placa']}'),
                subtitle: Text('Consultor: ${data['vendedor']}'),
                trailing: data['status'] == 'pendente'
                    ? const Icon(Icons.watch_later, color: Colors.orange)
                    : const Icon(Icons.check_circle, color: Colors.green),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _novoAgendamento(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}