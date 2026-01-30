import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class OtpBox extends StatelessWidget {
  final TextEditingController controller; // Pass controller to track individual digits

  const OtpBox({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 45,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          onChanged: (value) {
            if (value.length == 1) FocusScope.of(context).nextFocus();
          },
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: "",
          ),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}