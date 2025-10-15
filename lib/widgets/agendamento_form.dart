import 'package:flutter/material.dart';
import '../core/firebase_service.dart';
import '../core/notification_service.dart';
import '../models/agendamento.dart';
import '../core/formatters.dart';

class AgendamentoForm extends StatefulWidget {
  final String nomeVendedor;
  final String tokenDevice;

  const AgendamentoForm({
    super.key,
    required this.nomeVendedor,
    required this.tokenDevice,
  });

  @override
  State<AgendamentoForm> createState() => _AgendamentoFormState();
}

class _AgendamentoFormState extends State<AgendamentoForm> {
  final _formKey = GlobalKey<FormState>();
  final _corController = TextEditingController();
  final _placaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _horaController = TextEditingController();
  DateTime _dataSelecionada = DateTime.now();
  final _firebaseService = FirebaseService();

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      // 1️⃣ Pega o token do higienizador do Firestore
      final tokenHigienizador = await _firebaseService.pegarTokenHigienizador();

      // 2️⃣ Cria o agendamento com o token do higienizador
      final agendamento = Agendamento(
        vendedor: widget.nomeVendedor,
        cor: _corController.text,
        placa: _placaController.text,
        modelo: _modeloController.text,
        data: _dataSelecionada,
        hora: _horaController.text,
        tokenId: tokenHigienizador,
      );

      // 3️⃣ Salva no Firestore
      await _firebaseService.salvarAgendamento(agendamento.toMap());

      // 4️⃣ Notificação remota para o higienizador
      if (tokenHigienizador.isNotEmpty) {
        await NotificationService.sendToDevice(
          tokenHigienizador,
          'Novo agendamento',
          'Veículo ${agendamento.placa} - ${agendamento.modelo} precisa de higienização.',
        );
      }

      // 5️⃣ Notificação local para o vendedor
      await NotificationService.show(
        'Agendamento salvo',
        'Agendamento enviado para higienização.',
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo Agendamento'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _corController,
                decoration: const InputDecoration(labelText: 'Cor'),
                inputFormatters: [UpperCaseTextFormatter()],
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              TextFormField(
                controller: _placaController,
                decoration: const InputDecoration(labelText: 'Placa'),
                inputFormatters: [UpperCaseTextFormatter()],
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              TextFormField(
                controller: _modeloController,
                decoration: const InputDecoration(labelText: 'Modelo'),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              TextFormField(
                controller: _horaController,
                decoration: const InputDecoration(labelText: 'Hora'),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _salvar,
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
