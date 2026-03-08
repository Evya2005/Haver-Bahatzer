import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firestore_paths.dart';
import '../models/dog_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _dogs =>
      _db.collection(FirestorePaths.dogs);

  Stream<List<Dog>> watchDogs() {
    return _dogs
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Dog.fromFirestore).toList());
  }

  Future<String> addDog(Dog dog) async {
    final doc = await _dogs.add(dog.toMap());
    return doc.id;
  }

  Future<void> updateDog(Dog dog) {
    return _dogs.doc(dog.id).update(dog.toMap());
  }

  Future<void> deleteDog(String dogId) {
    return _dogs.doc(dogId).delete();
  }
}
