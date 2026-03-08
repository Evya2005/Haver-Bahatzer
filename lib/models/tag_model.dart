import 'package:cloud_firestore/cloud_firestore.dart';

class CustomTag {
  final String id;
  final String label;
  final int bgColor;
  final int textColor;

  const CustomTag({
    required this.id,
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  factory CustomTag.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomTag(
      id: doc.id,
      label: data['label'] as String? ?? '',
      bgColor: data['bgColor'] as int? ?? 0xFFE8F5E9,
      textColor: data['textColor'] as int? ?? 0xFF1B5E20,
    );
  }

  Map<String, dynamic> toMap() => {
        'label': label,
        'bgColor': bgColor,
        'textColor': textColor,
      };

  CustomTag copyWith({String? id, String? label, int? bgColor, int? textColor}) {
    return CustomTag(
      id: id ?? this.id,
      label: label ?? this.label,
      bgColor: bgColor ?? this.bgColor,
      textColor: textColor ?? this.textColor,
    );
  }
}
