import re

with open('lib/screens/ticket_detail_screen.dart', 'r') as f:
    content = f.read()

# 1. Extract Media part from basicDetails.
media_block = """                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isEditing) _buildMediaGallery(),
                          if (showCameraBox) ...[
                            if (isEditing) const Divider(height: 32),
                            Text(
                              (!isEditing || !canEditWorkDetails)
                                  ? "Upload issue photo *"
                                  : "Upload Completion Photos *",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildImageUploader(canEditWorkDetails),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),"""

content = content.replace(media_block, "")

# 2. Re-create Media part as `mediaDetails` widget before basicDetails
# find where basicDetails starts:
basic_start = "                final Widget basicDetails = Column("
media_widget = """                final Widget mediaDetails = (isEditing || showCameraBox) ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Media",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: navy,
                        ),
                      ),
                      const Divider(height: 24),
                      if (isEditing) _buildMediaGallery(),
                      if (showCameraBox) ...[
                        if (isEditing) const Divider(height: 32),
                        Text(
                          (!isEditing || !canEditWorkDetails)
                              ? "Upload issue photo *"
                              : "Upload Completion Photos *",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildImageUploader(canEditWorkDetails),
                      ],
                    ],
                  ),
                ) : const SizedBox.shrink();

"""
content = content.replace(basic_start, media_widget + basic_start)

# 3. Replace the return layout logic
old_return = """                return isWeb
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: basicDetails,
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                workDetails,
                                adminActions,
                                const SizedBox(height: 200),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          basicDetails,
                          workDetails,
                          adminActions,
                          const SizedBox(height: 200),
                        ],
                      );"""

new_return = """                final double screenWidth = MediaQuery.of(context).size.width;
                final bool isDesktop = screenWidth >= 1100;
                final bool isTablet = screenWidth >= 768 && screenWidth < 1100;

                if (isDesktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 10,
                        child: basicDetails,
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 12,
                        child: workDetails,
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 9,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            mediaDetails,
                            adminActions,
                            const SizedBox(height: 200),
                          ],
                        ),
                      ),
                    ],
                  );
                } else if (isTablet) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            basicDetails,
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            mediaDetails,
                            workDetails,
                            adminActions,
                            const SizedBox(height: 200),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      basicDetails,
                      mediaDetails,
                      workDetails,
                      adminActions,
                      const SizedBox(height: 200),
                    ],
                  );
                }"""
content = content.replace(old_return, new_return)

with open('lib/screens/ticket_detail_screen.dart', 'w') as f:
    f.write(content)

print("Safely replaced layout logic.")
