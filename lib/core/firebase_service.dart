import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final _firestore = FirebaseFirestore.instance;

  Future<void> salvarAgendamento(Map<String, dynamic> data) async {
    await _firestore.collection('hig_solicitacoes').add({
      ...data,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> atualizarStatus(String docId, String novoStatus) async {
    await _firestore.collection('hig_solicitacoes').doc(docId).update({
      'status': novoStatus,
    });
  }

  Future<void> atualizarToken(String docId, String tokenId) async {
    await _firestore.collection('hig_solicitacoes').doc(docId).update({
      'tokenId': tokenId,
    });
  }

  Stream<QuerySnapshot> listarAgendamentos() {
    return _firestore
        .collection('hig_solicitacoes')
        .orderBy('criadoEm', descending: true)
        .snapshots();
  }

  Future<Map<String, dynamic>?> getAgendamentoById(String docId) async {
    final doc = await _firestore.collection('hig_solicitacoes').doc(docId).get();
    if (doc.exists) return doc.data();
    return null;
  }

  Future<String> pegarTokenHigienizador() async {
  final query = await FirebaseFirestore.instance
      .collection('colaboradores')
      .where('cargo', isEqualTo: 'higienizador')
      .limit(1)
      .get();

  if (query.docs.isNotEmpty) {
    return query.docs.first.data()['deviceToken'] ?? '';
  }
  return '';
}

}
