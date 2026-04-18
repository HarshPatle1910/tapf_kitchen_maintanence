import 'package:flutter/material.dart';
import 'master_selector_sheet.dart';

void openMasterSelector({
  required BuildContext context,
  required String title,
  required List<String> items,
  required Function(String) onSelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    builder: (_) {
      return MasterSelectorSheet(
        title: title,
        items: items,
        onSelected: onSelected,
      );
    },
  );
}