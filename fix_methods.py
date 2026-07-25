import re

with open('lib/screens/ticket_detail_screen.dart', 'r') as f:
    content = f.read()

# Strip the last '}'
content = content.rstrip()[:-1]

methods_to_add = """
  Widget _buildInfoCard(String label, dynamic value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: Colors.blueGrey),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (value is Widget)
            value
          else
            Text(
              value.toString(),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobileDevice = MediaQuery.of(context).size.width < 768;
    if (!isMobileDevice) {
      return _buildWebTabletLayout(context);
    }
    return _buildMobileLayout(context);
  }
}
"""

with open('lib/screens/ticket_detail_screen.dart', 'w') as f:
    f.write(content + "\n" + methods_to_add)

