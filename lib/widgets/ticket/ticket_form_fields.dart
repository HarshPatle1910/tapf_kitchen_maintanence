import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TicketFormFields {
  static const Color navy = Color(0xFF26538D);
  static const Color golden = Color(0xFFD4AF37);

  static Widget buildTextField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    bool isReadOnly = false,
    bool isRequired = false,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: ctrl,
      readOnly: isReadOnly,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      validator: isRequired ? (val) => val == null || val.trim().isEmpty ? 'Required' : null : null,
      style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: isReadOnly ? Colors.grey.shade700 : navy, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: Padding(padding: EdgeInsets.only(bottom: maxLines > 1 ? (maxLines * 16.0) : 0), child: Icon(icon, color: Colors.grey.shade400, size: 20)),
        filled: true, fillColor: isReadOnly ? Colors.grey.shade100 : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: golden, width: 2)),
      ),
    );
  }

  static Widget buildDescriptionField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    bool isReadOnly = false,
    bool isRequired = false,
  }) {
    return _DescriptionFieldWidget(
      ctrl: ctrl,
      label: label,
      icon: icon,
      isReadOnly: isReadOnly,
      isRequired: isRequired,
    );
  }

  static Widget buildDropdown({
    required String label,
    required List<String> items,
    required String? val,
    required Function(String?)? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: val, isExpanded: true, dropdownColor: Colors.white, borderRadius: BorderRadius.circular(12),
      icon: const Icon(Icons.keyboard_arrow_down, color: navy, size: 20),
      style: GoogleFonts.inter(color: navy, fontWeight: FontWeight.w600, fontSize: 14),
      decoration: InputDecoration(
        labelText: label, labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
        filled: true, fillColor: onChanged == null ? Colors.grey.shade100 : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: golden, width: 2)),
      ),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
    );
  }

  static Widget buildSleekAutocomplete({
    Key? key,
    required BuildContext context,
    required String hint, required IconData icon, required TextEditingController controller, required FocusNode focusNode,
    required List<Map<String, dynamic>> options, required bool isDisabled, required Function(Map<String, dynamic>) onSelected, VoidCallback? onCleared,
  }) {
    return RawAutocomplete<Map<String, dynamic>>(
      key: key, textEditingController: controller, focusNode: focusNode,
      optionsBuilder: (val) {
        if (val.text.isEmpty) return options;
        return options.where((opt) => opt['display_name'].toString().toLowerCase().contains(val.text.toLowerCase()));
      },
      displayStringForOption: (opt) => opt['display_name'].toString(),
      onSelected: (sel) { onSelected(sel); focusNode.unfocus(); },
      fieldViewBuilder: (ctx, ctrl, fNode, onSub) => TextFormField(
        controller: ctrl, focusNode: fNode, enabled: !isDisabled,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: isDisabled ? Colors.grey.shade700 : navy),
        decoration: InputDecoration(
          labelText: hint, labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
          filled: true, fillColor: isDisabled ? Colors.grey.shade100 : Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: golden, width: 2)),
          suffixIcon: ctrl.text.isNotEmpty && !isDisabled
              ? IconButton(icon: const Icon(Icons.clear, size: 16, color: Colors.grey), onPressed: () { ctrl.clear(); if (onCleared != null) onCleared(); }) : null,
        ),
      ),
      optionsViewBuilder: (ctx, onSel, opts) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4.0, borderRadius: BorderRadius.circular(10),
          child: Container(
            constraints: BoxConstraints(maxHeight: 200, maxWidth: MediaQuery.of(context).size.width - 72),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: ListView.separated(
              padding: EdgeInsets.zero, shrinkWrap: true, itemCount: opts.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (ctx, idx) => ListTile(
                dense: true,
                title: Text(opts.elementAt(idx)['display_name'], style: GoogleFonts.inter(fontSize: 13, color: navy, fontWeight: FontWeight.w500)),
                onTap: () => onSel(opts.elementAt(idx)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DescriptionFieldWidget extends StatefulWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool isReadOnly;
  final bool isRequired;

  const _DescriptionFieldWidget({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.isReadOnly = false,
    this.isRequired = false,
  });

  @override
  State<_DescriptionFieldWidget> createState() => _DescriptionFieldWidgetState();
}

class _DescriptionFieldWidgetState extends State<_DescriptionFieldWidget> {
  static const Color navy = Color(0xFF26538D);
  static const Color golden = Color(0xFFD4AF37);
  static const int maxWords = 200;

  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    _updateWordCount();
    widget.ctrl.addListener(_updateWordCount);
  }

  @override
  void dispose() {
    widget.ctrl.removeListener(_updateWordCount);
    super.dispose();
  }

  void _updateWordCount() {
    final text = widget.ctrl.text.trim();
    final words = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    if (_wordCount != words) {
      setState(() {
        _wordCount = words;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isOverLimit = _wordCount > maxWords;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextFormField(
          controller: widget.ctrl,
          readOnly: widget.isReadOnly,
          minLines: 3,
          maxLines: null,
          textCapitalization: TextCapitalization.none,
          validator: (val) {
            if (widget.isRequired && (val == null || val.trim().isEmpty)) {
              return 'Required';
            }
            if (_wordCount > maxWords) {
              return 'Exceeded maximum word limit of $maxWords words.';
            }
            return null;
          },
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: widget.isReadOnly ? Colors.grey.shade700 : navy,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 40.0), // Align icon to top visually
              child: Icon(Icons.title, color: Colors.grey, size: 20),
            ),
            filled: true,
            fillColor: widget.isReadOnly ? Colors.grey.shade100 : Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isOverLimit ? Colors.red : Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isOverLimit ? Colors.red : Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isOverLimit ? Colors.red : golden, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$_wordCount / $maxWords words',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isOverLimit ? Colors.red : Colors.grey.shade600,
            fontWeight: isOverLimit ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}