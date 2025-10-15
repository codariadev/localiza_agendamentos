import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:localiza_agendamentos/main.dart';

/// Função para exibir notificação local
Future<void> mostrarNotificacaoLocal(String titulo, String corpo) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'agendamento_channel',
    'Agendamentos',
    channelDescription: 'Notificações de agendamentos',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  const NotificationDetails details = NotificationDetails(android: androidDetails);

  await localNotificationsPlugin.show(
    0,
    titulo,
    corpo,
    details,
  );
}

/// Atualiza status no Firestore e dispara notificação local se for o mesmo device
Future<void> atualizarStatusAgendamento(
    String docId, String novoStatus, String? meuDeviceToken) async {
  final docRef = FirebaseFirestore.instance.collection('hig_solicitacoes').doc(docId);

  await docRef.update({'status': novoStatus});

  final snapshot = await docRef.get();
  final data = snapshot.data();

  if (data != null &&
      data['deviceToken'] != null &&
      data['deviceToken'] == meuDeviceToken &&
      novoStatus.toLowerCase() == 'concluido') {
    await mostrarNotificacaoLocal(
      'Agendamento Concluído',
      'Seu agendamento foi marcado como concluído.',
    );
  }
}

/// Tela principal de listagem de agendamentos
class HigScreen extends StatelessWidget {
  final String nome;
  final String? deviceToken;

const HigScreen({super.key, required this.nome, required this.deviceToken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agendamentos',
      theme: ThemeData(
        colorSchemeSeed: const Color.fromRGBO(8, 143, 66, 1),
        useMaterial3: false,
      ),
      home: MyHigScreenState(
        title: 'Olá, $nome',
        nomeVendedor: nome,
        deviceToken: deviceToken,
      ),
    );
  }
}

class MyHigScreenState extends StatefulWidget {
  final String title;
  final String nomeVendedor;
  final String? deviceToken;

  const MyHigScreenState({
    super.key,
    required this.title,
    required this.nomeVendedor,
    this.deviceToken,
  });

  @override
  State<MyHigScreenState> createState() => _MyHigScreenState();
}

class _MyHigScreenState extends State<MyHigScreenState> {
  StreamSubscription<QuerySnapshot>? _listener;

  @override
  void initState() {
    super.initState();
    _escutarAlteracoesAgendamentos();
  }

  /// Escuta em tempo real as alterações na coleção e dispara notificação local se o status mudar
  void _escutarAlteracoesAgendamentos() {
    _listener = FirebaseFirestore.instance
        .collection('hig_solicitacoes')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docChanges) {
        if (doc.type == DocumentChangeType.modified) {
          final data = doc.doc.data();
          if (data == null) continue;

          final status = data['status']?.toString().toLowerCase();
          final deviceToken = data['deviceToken'];

          if (status == 'concluido' && deviceToken == widget.deviceToken) {
            mostrarNotificacaoLocal(
              'Agendamento Concluído',
              'Seu agendamento foi marcado como concluído.',
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _listener?.cancel();
    super.dispose();
  }

  String _formatarData(String? isoDate) {
    if (isoDate == null) return '';
    final date = DateTime.parse(isoDate);
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color.fromRGBO(8, 143, 66, 1),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('hig_solicitacoes')
            .orderBy('criadoEm', descending: true)
            .where('status', isEqualTo: 'pendente')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum agendamento encontrado.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  child: ListTile(
                    title: Text(
                      data['vendedor'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      'Modelo: ${data['modelo'] ?? ''}\n'
                      'Placa: ${data['placa'] ?? ''}\n'
                      'Cor: ${data['cor'] ?? ''}\n'
                      'Data: ${_formatarData(data['data'])} às ${data['hora'] ?? ''}',
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: data['status'] == 'pendente'
                            ? Colors.orange
                            : Colors.green,
                      ),
                      onPressed: data['status'] == 'pendente'
                          ? () async {
                              await atualizarStatusAgendamento(
                                docId,
                                'concluido',
                                widget.deviceToken,
                              );
                            }
                          : null,
                      child: Text(
                        (data['status'] ?? '').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    isThreeLine: true,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
