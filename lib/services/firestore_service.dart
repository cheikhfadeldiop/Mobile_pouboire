import 'package:cloud_firestore/cloud_firestore.dart';

/// Service responsable des operations CRUD sur la collection Firestore.
class FirestoreService {
  final CollectionReference _calculations =
      FirebaseFirestore.instance.collection('calculations');

  /// Enregistre un nouveau calcul de pourboire dans Firestore.
  Future<void> saveCalculation({
    required double montant,
    required int pourcentage,
    required double pourboire,
    required double total,
    required String devise,
  }) async {
    await _calculations.add({
      'montant': montant,
      'pourcentage': pourcentage,
      'pourboire': pourboire,
      'total': total,
      'devise': devise,
      'date': FieldValue.serverTimestamp(),
    });
  }

  /// Retourne un stream temps reel de tous les calculs, tries par date
  /// decroissante (le plus recent en premier).
  Stream<QuerySnapshot> getCalculations() {
    return _calculations.orderBy('date', descending: true).snapshots();
  }

  /// Supprime un calcul par son identifiant de document.
  Future<void> deleteCalculation(String docId) async {
    await _calculations.doc(docId).delete();
  }
}
