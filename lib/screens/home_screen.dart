import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// -------------------- Formatter para caixa alta --------------------
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

// -------------------- Modelo de Agendamento --------------------
class Agendamento {
  String vendedor;
  String cor;
  String placa;
  String modelo;
  DateTime data;
  String hora;
  String status;

  Agendamento({
    required this.vendedor,
    required this.cor,
    required this.placa,
    required this.modelo,
    required this.data,
    required this.hora,
    this.status = 'pendente',
  });
}

// -------------------- Função para atualizar status --------------------
Future<void> atualizarStatusAgendamento(String docId, String novoStatus) async {
  await FirebaseFirestore.instance
      .collection('hig_solicitacoes')
      .doc(docId)
      .update({'status': novoStatus});
}

// -------------------- TELA INICIAL --------------------
class HomeScreen extends StatelessWidget {
  final String nomeVendedor;
  const HomeScreen({super.key, required this.nomeVendedor, required deviceToken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Localiza Agendamentos',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF088F42),
        useMaterial3: false,
      ),
      home: MyHomePage(title: 'Olá $nomeVendedor.', nomeVendedor: nomeVendedor),
    );
  }
}

// -------------------- PÁGINA PRINCIPAL --------------------
class MyHomePage extends StatefulWidget {
  final String title;
  final String nomeVendedor;

  const MyHomePage({super.key, required this.title, required this.nomeVendedor});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _formatarData(String? isoDate) {
    if (isoDate == null) return '';
    final date = DateTime.parse(isoDate);
    return '${date.day}/${date.month}/${date.year}';
  }

  void _abrirFormulario() {
    showDialog(
      context: context,
      builder: (_) => AgendamentoForm(nomeVendedor: widget.nomeVendedor),
    );
  }

  Widget _buildAgendamentoCard(Map<String, dynamic> data, String docId) {
    final status = (data['status'] ?? 'pendente').toString().toLowerCase();

    Color statusColor = status == 'concluido' || status == 'concluído'
        ? Colors.green
        : Colors.red;
    String statusText = status == 'concluido' || status == 'concluído'
        ? 'Concluído'
        : 'Pendente';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        title: Text(
          data['vendedor'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Modelo: ${data['modelo'] ?? ''}\n'
          'Placa: ${data['placa'] ?? ''}\n'
          'Cor: ${data['cor'] ?? ''}\n'
          'Data: ${_formatarData(data['data'])} às ${data['hora'] ?? ''}',
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            border: Border.all(color: statusColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF088F42),
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('hig_solicitacoes')
            .orderBy('criadoEm', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum agendamento encontrado.\nClique no + para adicionar.',
                textAlign: TextAlign.center,
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
              return _buildAgendamentoCard(data, docId);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: _abrirFormulario,
        tooltip: 'Novo Agendamento',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// -------------------- FORMULÁRIO DE AGENDAMENTO --------------------
class AgendamentoForm extends StatefulWidget {
  final String nomeVendedor;
  const AgendamentoForm({super.key, required this.nomeVendedor});

  @override
  State<AgendamentoForm> createState() => _AgendamentoFormState();
}

class _AgendamentoFormState extends State<AgendamentoForm> {
  final _formKey = GlobalKey<FormState>();
  final _placaController = TextEditingController();
  final _corController = TextEditingController();
  final _modeloController = TextEditingController();

  DateTime? _dataSelecionada;
  TimeOfDay? _horaSelecionada;

  Future<void> _selecionarData(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dataSelecionada = picked);
  }

  Future<void> _selecionarHora(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _horaSelecionada = picked);
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() &&
        _dataSelecionada != null &&
        _horaSelecionada != null) {
      final novoAgendamento = Agendamento(
        vendedor: widget.nomeVendedor,
        placa: _placaController.text,
        cor: _corController.text,
        modelo: _modeloController.text,
        data: _dataSelecionada!,
        hora: _horaSelecionada!.format(context),
      );

      await FirebaseFirestore.instance.collection('hig_solicitacoes').add({
        'vendedor': novoAgendamento.vendedor,
        'placa': novoAgendamento.placa,
        'cor': novoAgendamento.cor,
        'modelo': novoAgendamento.modelo,
        'data': novoAgendamento.data.toIso8601String(),
        'hora': novoAgendamento.hora,
        'status': novoAgendamento.status,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agendamento salvo com sucesso!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Preencha todos os campos e selecione data e hora.')),
      );
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Vendedor: ${widget.nomeVendedor}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                      fontSize: 16),
                ),
              ),
              TextFormField(
                controller: _placaController,
                decoration: const InputDecoration(labelText: 'Placa'),
                validator: (value) =>
                    value!.isEmpty ? 'Informe a placa' : null,
                inputFormatters: [UpperCaseTextFormatter()],
              ),
              TextFormField(
                controller: _corController,
                decoration: const InputDecoration(labelText: 'Cor'),
                validator: (value) => value!.isEmpty ? 'Informe a cor' : null,
                inputFormatters: [UpperCaseTextFormatter()],
              ),
              TextFormField(
                controller: _modeloController,
                decoration: const InputDecoration(labelText: 'Modelo'),
                validator: (value) =>
                    value!.isEmpty ? 'Informe o modelo' : null,
                inputFormatters: [UpperCaseTextFormatter()],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(_dataSelecionada == null
                        ? 'Nenhuma data selecionada'
                        : 'Data: ${_dataSelecionada!.day}/${_dataSelecionada!.month}/${_dataSelecionada!.year}'),
                  ),
                  TextButton(
                    onPressed: () => _selecionarData(context),
                    child: const Text('Selecionar Data'),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(_horaSelecionada == null
                        ? 'Nenhuma hora selecionada'
                        : 'Hora: ${_horaSelecionada!.format(context)}'),
                  ),
                  TextButton(
                    onPressed: () => _selecionarHora(context),
                    child: const Text('Selecionar Hora'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _submitForm,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
          child: const Text('Salvar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
