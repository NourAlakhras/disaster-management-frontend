import 'package:flutter/material.dart';
import 'package:flutter_3/utils/app_colors.dart'; // Import your color definitions

class EditableFieldWidget extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isValid;
  final String? errorText;
  final bool isEditing;
  final ValueChanged<String>? onChanged; // Add this parameter

  const EditableFieldWidget({
    Key? key,
    required this.label,
    required this.controller,
    required this.isValid,
    this.errorText,
    this.isEditing = true, // Default to true
    this.onChanged, // Initialize this parameter
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryTextColor,
          ),
        ),
        TextFormField(
          controller: controller,
          style: const TextStyle(
            color: primaryTextColor,
          ),
          onChanged: onChanged, // Use the onChanged callback
          decoration: InputDecoration(
            errorText: errorText,
          ),
          enabled: isEditing, // Control whether the field is editable
        ),
      ],
    );
  }
}
