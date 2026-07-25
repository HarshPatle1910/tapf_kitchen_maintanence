import re

with open('lib/screens/ticket_detail_screen.dart', 'r') as f:
    content = f.read()

# 1. Break basicDetails into:
# - ticketHeader (status, time, timeline)
# - ticketGeneral (kitchen, area, eq, priority, cat, breakdown, desc)
# - ticketMedia (photos)

basic_start = "                final Widget basicDetails = Column("
basic_idx = content.find(basic_start)

# We want to rename `basicDetails` to `ticketHeader` and close it before `ticketGeneral`
# The start of ticketGeneral is `if (authProv.assignedKitchens.length > 1) ...[`
general_start_marker = "                      if (authProv.assignedKitchens.length > 1) ...["
general_idx = content.find(general_start_marker, basic_idx)

# We close ticketHeader and start ticketGeneral
replacement1 = """                  ],
                );
                
                final Widget ticketGeneral = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (authProv.assignedKitchens.length > 1) ...["""
content = content.replace("                      if (authProv.assignedKitchens.length > 1) ...[", replacement1, 1)
content = content.replace("final Widget basicDetails = Column(", "final Widget ticketHeader = Column(", 1)

# Now we need to extract ticketMedia from ticketGeneral.
# Media starts at `if (isEditing) _buildMediaGallery(),`
# Actually it is inside a Column.
media_marker = """                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isEditing) _buildMediaGallery(),"""
media_idx = content.find(media_marker, general_idx)

replacement2 = """                    ],
                  ),
                );
                
                final Widget ticketMedia = (isEditing || showCameraBox) ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isEditing) _buildMediaGallery(),"""
content = content.replace(media_marker, replacement2, 1)

# Now we need to close ticketMedia and re-open ticketGeneral2 (the rest of the form)
# ticketMedia ends right after `_buildImageUploader(canEditWorkDetails), ], ], ), const SizedBox(height: 12),`
media_end_marker = """                            _buildImageUploader(canEditWorkDetails),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),"""
replacement3 = """                            _buildImageUploader(canEditWorkDetails),
                          ],
                    ],
                  ),
                ) : const SizedBox.shrink();
                
                final Widget ticketGeneral2 = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: ["""
content = content.replace(media_end_marker, replacement3, 1)

with open('lib/screens/ticket_detail_screen.dart', 'w') as f:
    f.write(content)

print("Step 1 done")
