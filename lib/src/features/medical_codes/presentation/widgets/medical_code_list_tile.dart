import 'package:flutter/material.dart';
import '../../domain/entities/medical_code.dart';

class MedicalCodeListTile extends StatelessWidget {
  final MedicalCode code;
  final VoidCallback? onTap;
  final Widget? trailing;

  const MedicalCodeListTile({
    super.key,
    required this.code,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(code.code),
      subtitle: Text(code.description),
      onTap: onTap,
      trailing: trailing,
    );
  }
}




