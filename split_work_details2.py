import re

with open('lib/screens/ticket_detail_screen.dart', 'r') as f:
    content = f.read()

workDetails_start = "                final Widget workDetails = Column("
workDetails_idx = content.find(workDetails_start)

# The point where we want to split:
split_marker = """                        const SizedBox(height: 24),

                        Text(
                          "Tools Checked Out","""

split_idx = content.find(split_marker, workDetails_idx)

# Part 1: from workDetails_idx to split_idx. We want to close workDetailsContent here.
# Inside that, we will replace `final Widget workDetails = Column(` with `final Widget workDetailsContent = Column(`
part1 = content[workDetails_idx:split_idx]
part1 = part1.replace("final Widget workDetails = Column(", "final Widget workDetailsContent = Column(")
# Now close the children list, Column, Container, and if statement.
part1 += """                      ],
                    ),
                  ),
                ] else ...[
                  Text("Work details are only available when ticket is in progress or completed.", style: GoogleFonts.inter(color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                ]
              ],
            );
            
"""

# Part 2: from split_idx to the end of workDetails block.
# We will start `final Widget partsAndTools = Column(`
part2 = """            final Widget partsAndTools = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (currentStatus == 'IN_PROGRESS' || currentStatus == 'COMPLETED' || currentStatus == 'VERIFIED') ...[
""" + content[split_idx:content.find("                final Widget adminActions = Column(", split_idx)]

# We need to insert these parts and replace the old workDetails block.
end_idx = content.find("                final Widget adminActions = Column(", split_idx)
old_full = content[workDetails_idx:end_idx]

content = content.replace(old_full, part1 + part2)

# Now we need to update the bottom return block.
old_return = """                final double screenWidth = MediaQuery.of(context).size.width;
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

new_return = """                final double screenWidth = MediaQuery.of(context).size.width;
                final bool isMobileDevice = screenWidth < 768;

                if (!isMobileDevice) {
                  return _buildWebTabletLayout(
                    context, 
                    authProv, 
                    ticketProv, 
                    isAdmin, 
                    isAssignedWorker, 
                    canEditWorkDetails, 
                    readOnlyFields, 
                    showCameraBox, 
                    activeKitchenName, 
                    activeKitchenId, 
                    availableEquipments, 
                    adminActions, 
                    workDetailsContent, 
                    partsAndTools,
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      basicDetails,
                      mediaDetails,
                      workDetailsContent,
                      partsAndTools,
                      adminActions,
                      const SizedBox(height: 200),
                    ],
                  );
                }"""
content = content.replace(old_return, new_return)

with open('lib/screens/ticket_detail_screen.dart', 'w') as f:
    f.write(content)

print("Split logic successfully")
