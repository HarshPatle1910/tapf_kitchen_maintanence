import re

with open('lib/screens/ticket_detail_screen.dart', 'r') as f:
    content = f.read()

start_str = """                final Widget basicDetails = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                if (isEditing) ...["""

end_of_timeline_str = """                  TicketTimeline(ticket: _localTicket!),
                  const SizedBox(height: 12),
                ],

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,"""

# First, let's find the exact indices
start_idx = content.find(start_str)
end_idx = content.find(end_of_timeline_str)

if start_idx == -1 or end_idx == -1:
    print("Could not find boundaries!")
    print(start_idx, end_idx)
    exit(1)

# Extract the timeline content
timeline_content = content[start_idx + len(start_str) : end_idx]

replacement = """                final Widget statusAndTimelineSection = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isEditing) ...[""" + timeline_content + """                  TicketTimeline(ticket: _localTicket!),
                  const SizedBox(height: 12),
                ] else Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("Status & Timeline available after creation.", style: GoogleFonts.inter(color: Colors.grey.shade500)),
                ),
                  ],
                );

                final Widget ticketDetailsSection = Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,"""

# Now we need to also redefine basicDetails so that mobile layout works without changes
# Wait, basicDetails is not needed if we just update the mobile layout to use the new sections!
# But let's just keep basicDetails for mobile layout compatibility!
# Actually, the original code had basicDetails, workDetails, adminActions.
# Let's just redefine basicDetails:
basic_details_redef = """
                final Widget basicDetails = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    statusAndTimelineSection,
                    ticketDetailsSection,
                  ],
                );
"""

# Wait, ticketDetailsSection is a Container that ends around line 2271.
# I can just insert `statusAndTimelineSection` before `ticketDetailsSection`
# and rename the original `basicDetails` to `ticketDetailsSection`.

# Let's do it this way:
new_code = replacement

# We replace from start_idx to end_idx + len(end_of_timeline_str)
content = content[:start_idx] + new_code + content[end_idx + len(end_of_timeline_str):]

# Now we need to find where the `basicDetails` Column ends, which is `                  ],\n                );` right before `final Widget workDetails = Column(`
work_details_str = """                final Widget workDetails = Column("""
work_idx = content.find(work_details_str)

# We insert `basic_details_redef` right before `workDetails`
# The end of ticketDetailsSection (which is the old basicDetails) is just before work_idx
# Let's find the `                );` before work_idx
end_of_basic_details_idx = content.rfind("                );", 0, work_idx)
if end_of_basic_details_idx != -1:
    content = content[:end_of_basic_details_idx + 18] + basic_details_redef + content[end_of_basic_details_idx + 18:]

with open('lib/screens/ticket_detail_screen.dart', 'w') as f:
    f.write(content)
print("Successfully split basicDetails!")
