// Standardized Search Field — مشروع «مُعين» (Mouin)
import 'package:flutter/material.dart';

class MouinSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const MouinSearchField({
    super.key,
    required this.controller,
    this.hintText = 'بحث في كل العناصر...',
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: value.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controller.clear();
                      if (onClear != null) onClear!();
                      if (onChanged != null) onChanged!('');
                    },
                  )
                : null,
          ),
        );
      },
    );
  }
}
