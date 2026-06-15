import 'dart:io';

import 'package:blood_donation/Controller/AuthController/AuthController.dart';
import 'package:blood_donation/Theme/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfilePhotoPicker extends StatelessWidget {
  const ProfilePhotoPicker({super.key, required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedFile = controller.selectedProfilePic.value;
      final savedUrl = controller.savedProfilePicUrl;
      final ImageProvider? imageProvider = selectedFile != null
          ? FileImage(selectedFile)
          : savedUrl == null
          ? null
          : NetworkImage(savedUrl);
      final fileName = controller.fileName(selectedFile);
      final isBusy = controller.isMediaUploadLoading.value;

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.textFieldColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              height: 74,
              width: 74,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: .16),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageProvider == null
                  ? Icon(
                      Icons.person_outline,
                      color: AppColors.primaryColor,
                      size: 34,
                    )
                  : Image(
                      image: imageProvider,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person_outline,
                        color: AppColors.primaryColor,
                        size: 34,
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Profile photo",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedFile == null
                        ? savedUrl == null
                              ? "No photo selected"
                              : "Current photo"
                        : fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: isBusy ? null : controller.pickProfilePic,
                        icon: const Icon(Icons.photo_camera_outlined, size: 18),
                        label: Text(selectedFile == null ? "Choose" : "Change"),
                        style: _buttonStyle(),
                      ),
                      if (selectedFile != null)
                        IconButton(
                          tooltip: "Remove selected photo",
                          onPressed: isBusy
                              ? null
                              : controller.clearSelectedProfilePic,
                          icon: const Icon(Icons.close),
                          color: Colors.black54,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class ProofDocumentPicker extends StatelessWidget {
  const ProofDocumentPicker({
    super.key,
    required this.controller,
    this.requireProof = false,
  });

  final AuthController controller;
  final bool requireProof;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final frontFile = controller.proofFrontFile.value;
      final backFile = controller.proofBackFile.value;
      final isBusy = controller.isMediaUploadLoading.value;
      final showRequiredMessage =
          requireProof && (frontFile == null || backFile == null);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "ID Proof",
            style: TextStyle(
              color: Colors.black87,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          if (showRequiredMessage) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: .3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.redAccent, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Please upload ID proof front and back.",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: _ProofImageTile(
                  label: "Front",
                  icon: Icons.badge_outlined,
                  file: frontFile,
                  isBusy: isBusy,
                  fileName: controller.fileName(frontFile),
                  onPick: controller.pickProofFront,
                  onClear: controller.clearProofFront,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ProofImageTile(
                  label: "Back",
                  icon: Icons.assignment_ind_outlined,
                  file: backFile,
                  isBusy: isBusy,
                  fileName: controller.fileName(backFile),
                  onPick: controller.pickProofBack,
                  onClear: controller.clearProofBack,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}

class _ProofImageTile extends StatelessWidget {
  const _ProofImageTile({
    required this.label,
    required this.icon,
    required this.file,
    required this.isBusy,
    required this.fileName,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final IconData icon;
  final File? file;
  final bool isBusy;
  final String fileName;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.textFieldColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.12,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: .16),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _preview(),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            file == null ? "No file selected" : fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isBusy ? null : onPick,
              icon: Icon(file == null ? Icons.upload_file : Icons.swap_horiz),
              label: Text(file == null ? "Upload" : "Change"),
              style: _buttonStyle(),
            ),
          ),
          if (file != null)
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: isBusy ? null : onClear,
                icon: const Icon(Icons.close, size: 18),
                label: const Text("Remove"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black54,
                  minimumSize: const Size(0, 36),
                  padding: EdgeInsets.zero,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _preview() {
    final selectedFile = file;
    if (selectedFile == null) {
      return Icon(icon, color: AppColors.primaryColor, size: 34);
    }

    if (_isImage(selectedFile)) {
      return Image.file(
        selectedFile,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          Icons.description_outlined,
          color: AppColors.primaryColor,
          size: 34,
        ),
      );
    }

    return Icon(
      Icons.picture_as_pdf_outlined,
      color: AppColors.primaryColor,
      size: 34,
    );
  }

  bool _isImage(File selectedFile) {
    final path = selectedFile.path.toLowerCase();
    return path.endsWith(".jpg") ||
        path.endsWith(".jpeg") ||
        path.endsWith(".png");
  }
}

ButtonStyle _buttonStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: AppColors.primaryColor,
    side: BorderSide(color: AppColors.primaryColor.withValues(alpha: .4)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: const TextStyle(fontWeight: FontWeight.w800),
  );
}
