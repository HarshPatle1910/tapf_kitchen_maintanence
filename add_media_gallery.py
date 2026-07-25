import re

with open('lib/screens/ticket_detail_screen.dart', 'r') as f:
    content = f.read()

# Add _buildWebTabletMediaGallery
new_method = """
  Widget _buildWebTabletMediaGallery() {
    if (_isLoadingMedia) {
      return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(color: golden)));
    }
    if (_beforeUrls.isEmpty && _afterUrls.isEmpty) {
      return Text("No photos attached yet.", style: GoogleFonts.inter(color: Colors.grey.shade500, fontStyle: FontStyle.italic));
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_beforeUrls.isNotEmpty)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("BEFORE (Issue Raised)", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 14)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _beforeUrls.map((url) {
                    return GestureDetector(
                      onTap: () => _openImageViewer(context, url),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(url, height: 160, width: 160, fit: BoxFit.cover),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        if (_beforeUrls.isNotEmpty && _afterUrls.isNotEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Icon(Icons.arrow_forward_rounded, size: 32, color: Colors.green),
          ),
        if (_afterUrls.isNotEmpty)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("AFTER (Work Completed)", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _afterUrls.map((url) {
                    return GestureDetector(
                      onTap: () => _openImageViewer(context, url),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(url, height: 160, width: 160, fit: BoxFit.cover),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }
"""

content = content.replace("  Widget _buildWebTabletLayout(BuildContext context) {", new_method + "\n  Widget _buildWebTabletLayout(BuildContext context) {")
content = content.replace("if (isEditing) _buildMediaGallery(),", "if (isEditing) _buildWebTabletMediaGallery(),", 1) # Only replace the one inside the Photos tab

with open('lib/screens/ticket_detail_screen.dart', 'w') as f:
    f.write(content)

print("Added _buildWebTabletMediaGallery")
