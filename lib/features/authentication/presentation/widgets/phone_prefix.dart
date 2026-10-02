import 'package:flutter/material.dart';

/// Préfixe « 🇨🇩 +243 » affiché devant les champs téléphone.
class PhonePrefix extends StatelessWidget {
  const PhonePrefix({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🇨🇩', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 6),
        Text(
          '+243',
          style: Theme.of(
            context,
          ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 10),
        Container(width: 1, height: 22, color: Colors.grey.shade300),
      ],
    );
  }
}
