import re

with open('lib/screens/ticket_detail_screen.dart', 'r') as f:
    content = f.read()

old_return_block = """                return isWeb
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

new_return_block = """                Widget buildSectionHeader(String title, IconData icon) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0, top: 4.0),
                    child: Row(
                      children: [
                        Icon(icon, color: navy, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: navy,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final double screenWidth = MediaQuery.of(context).size.width;

                if (screenWidth >= 1100) {
                  // 3-Column Desktop Layout
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card 3: Images & Ticket Details
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildSectionHeader("Ticket Information", Icons.description),
                            ticketDetailsSection,
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Card 2: Work Details & Assigned Worker
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildSectionHeader("Work & Assignment", Icons.engineering),
                            if (currentStatus == 'RAISED' && (!isEditing || !isAdmin))
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Text(
                                  "No work has commenced on this ticket yet.",
                                  style: GoogleFonts.inter(
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            workDetails,
                            adminActions,
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Card 1: Status, Activity Timeline, Raised On
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildSectionHeader("Status & Timeline", Icons.history),
                            statusAndTimelineSection,
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ],
                  );
                } else if (screenWidth >= 768) {
                  // 2-Column Tablet/Medium Layout
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildSectionHeader("Ticket Information", Icons.description),
                            ticketDetailsSection,
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildSectionHeader("Status & Timeline", Icons.history),
                            statusAndTimelineSection,
                            const SizedBox(height: 24),
                            buildSectionHeader("Work & Assignment", Icons.engineering),
                            workDetails,
                            adminActions,
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  // 1-Column Mobile Layout
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildSectionHeader("Status & Timeline", Icons.history),
                      statusAndTimelineSection,
                      const SizedBox(height: 20),
                      buildSectionHeader("Work & Assignment", Icons.engineering),
                      workDetails,
                      adminActions,
                      const SizedBox(height: 20),
                      buildSectionHeader("Ticket Information", Icons.description),
                      ticketDetailsSection,
                      const SizedBox(height: 100),
                    ],
                  );
                }"""

if old_return_block not in content:
    print("Could not find old_return_block!")
    exit(1)

content = content.replace(old_return_block, new_return_block)

with open('lib/screens/ticket_detail_screen.dart', 'w') as f:
    f.write(content)

print("Successfully replaced layout return block!")
