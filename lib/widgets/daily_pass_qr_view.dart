import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/app_colors.dart';

/// QR de check-in gerado sempre a partir do mesmo [payload] (código da diária).
class DailyPassQrView extends StatelessWidget {
  const DailyPassQrView({
    super.key,
    required this.payload,
    this.size = 200,
  });

  final String payload;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: QrImageView(
          data: payload,
          size: size,
          padding: EdgeInsets.zero,
          backgroundColor: Colors.white,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: AppColors.foreground,
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: AppColors.foreground,
          ),
        ),
      ),
    );
  }
}
