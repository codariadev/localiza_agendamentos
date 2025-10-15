import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);

    final senhaDigitada = _passwordController.text.trim();

    if (senhaDigitada.isEmpty) {
      _showError('Informe a senha');
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Busca primeiro se é vendedor
      final queryVendedor = await FirebaseFirestore.instance
          .collection('colaboradores')
          .where('senha', isEqualTo: senhaDigitada)
          .where('cargo', isEqualTo: 'vendedor')
          .get();

      // Busca depois se é higienizador
      final queryHigienizador = await FirebaseFirestore.instance
          .collection('colaboradores')
          .where('senha', isEqualTo: senhaDigitada)
          .where('cargo', isEqualTo: 'higienizador')
          .get();

      // Se for vendedor
      if (queryVendedor.docs.isNotEmpty) {
        final userData = queryVendedor.docs.first.data();
        final nome = userData['nome'] ?? 'Usuário';
        final deviceToken = await FirebaseMessaging.instance.getToken();

        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: {'nome': nome, 'deviceToken': deviceToken},
        );
      }
      // Se for higienizador
      else if (queryHigienizador.docs.isNotEmpty) {
        final userData = queryHigienizador.docs.first.data();
        final nome = userData['nome'] ?? 'Usuário';
        final deviceToken = await FirebaseMessaging.instance.getToken();

        Navigator.pushReplacementNamed(
          context,
          '/hig_screen', // ✅ certifique-se de que esta rota existe no main.dart
          arguments: {'nome': nome, 'deviceToken': deviceToken},
        );
      }
      // Se não for nenhum dos dois
      else {
        _showError('Senha incorreta ou cargo inválido');
      }
    } catch (e) {
      _showError('Ocorreu um erro: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: const Color.fromRGBO(8, 143, 66, 1),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Center(
                child: Image.asset(
                  'lib/assets/images/splash.png',
                  width: 200,
                  height: 200,
                  fit:BoxFit.contain
                )
              ),
              const Spacer(),
              const SizedBox(height: 40),
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color.fromRGBO(241,124,39,1),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Digite sua senha',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color.fromRGBO(241,124,39,1), width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color.fromRGBO(241,124,39,1), width: 2),
                    ),
                    prefixIcon:
                        const Icon(Icons.lock, color: Color.fromRGBO(241,124,39,1)),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 250,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(241,124,39,1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),
                        const Spacer(),
            ],
          ),
        ),
      ),
      backgroundColor: const Color.fromRGBO(8, 143, 66, 1),
      
    );
  }
}
