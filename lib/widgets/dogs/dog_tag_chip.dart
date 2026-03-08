import 'package:flutter/material.dart';
import '../../models/tag_model.dart';

class DogTagChip extends StatelessWidget {
  final CustomTag tag;
  final bool small;

  const DogTagChip({super.key, required this.tag, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: Color(tag.bgColor),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tag.label,
        style: TextStyle(
          color: Color(tag.textColor),
          fontSize: small ? 11 : 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
