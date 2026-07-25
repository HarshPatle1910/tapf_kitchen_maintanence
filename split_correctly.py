import re

with open('lib/screens/ticket_detail_screen.dart', 'r') as f:
    content = f.read()

# Part 1: Start of statusAndTimelineSection
old_part1 = """                final Widget basicDetails = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                if (isEditing) ...["""

new_part1 = """                final Widget statusAndTimelineSection = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                if (isEditing) ...["""

# Part 2: Middle split between timeline and ticket details
old_part2 = """                  TicketTimeline(ticket: _localTicket!),
                  const SizedBox(height: 12),
                ],

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,"""

new_part2 = """                  TicketTimeline(ticket: _localTicket!),
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

# Part 3: End of ticketDetailsSection
old_part3 = """                            ? null
                            : (val) => setState(() => _category = val!),
                      ),
                    ],
                  ),
                ),

                  ],
                );

                final Widget workDetails = Column("""

new_part3 = """                            ? null
                            : (val) => setState(() => _category = val!),
                      ),
                    ],
                  ),
                );

                final Widget basicDetails = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    statusAndTimelineSection,
                    const SizedBox(height: 12),
                    ticketDetailsSection,
                  ],
                );

                final Widget workDetails = Column("""

if old_part1 not in content:
    print("Error: old_part1 not found!")
    exit(1)
if old_part2 not in content:
    print("Error: old_part2 not found!")
    exit(1)
if old_part3 not in content:
    print("Error: old_part3 not found!")
    exit(1)

content = content.replace(old_part1, new_part1)
content = content.replace(old_part2, new_part2)
content = content.replace(old_part3, new_part3)

with open('lib/screens/ticket_detail_screen.dart', 'w') as f:
    f.write(content)

print("Successfully replaced all 3 parts without syntax error!")
