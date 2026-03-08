import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firestore_paths.dart';
import '../models/tag_model.dart';

class TagService {
  final _col = FirebaseFirestore.instance.collection(FirestorePaths.tags);

  Stream<List<CustomTag>> watchTags() => _col.snapshots().map(
        (snap) => snap.docs.map((d) => CustomTag.fromFirestore(d)).toList(),
      );

  /// Seeds the 3 built-in tags only if the collection is empty.
  Future<void> seedInitialTags() async {
    final snap = await _col.limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final t in _initial) {
      final ref = _col.doc(t['id'] as String);
      batch.set(ref, {
        'label': t['label'],
        'bgColor': t['bgColor'],
        'textColor': t['textColor'],
      });
    }
    await batch.commit();
  }

  Future<String> addTag(String label, int bgColor, int textColor) async {
    final ref = await _col.add({
      'label': label,
      'bgColor': bgColor,
      'textColor': textColor,
    });
    return ref.id;
  }

  Future<void> updateTag(CustomTag tag) => _col.doc(tag.id).update(tag.toMap());

  Future<void> deleteTag(String tagId) => _col.doc(tagId).delete();
}

const _initial = [
  {'id': 'aggressive', 'label': 'תוקפני', 'bgColor': 0xFFFFCDD2, 'textColor': 0xFFC62828},
  {'id': 'medication', 'label': 'תרופות', 'bgColor': 0xFFE3F2FD, 'textColor': 0xFF1565C0},
  {'id': 'escapist', 'label': 'בורח', 'bgColor': 0xFFFFF9C4, 'textColor': 0xFF7B4500},
];
