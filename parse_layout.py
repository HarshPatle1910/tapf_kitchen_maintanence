import re

with open('lib/screens/ticket_detail_screen.dart', 'r') as f:
    content = f.read()

# Let's find basicDetails
basic_match = re.search(r'final Widget basicDetails = Column\([\s\S]*?children: \[\n\s*if \(isEditing\) \.\.\.\[([\s\S]*?)\],([\s\S]*?)\n\s*\],\n\s*\);', content)
if basic_match:
    status_timeline_code = basic_match.group(1)
    ticket_details_code = basic_match.group(2)
    print("Found basicDetails splits!")
    print("Status/Timeline length:", len(status_timeline_code))
    print("Ticket Details length:", len(ticket_details_code))
else:
    print("Failed to find basicDetails")

# Let's find workDetails
work_match = re.search(r'final Widget workDetails = Column\(([\s\S]*?)\n\s*\);\n', content)
if work_match:
    work_details_code = work_match.group(1)
    print("Found workDetails! Length:", len(work_details_code))
else:
    print("Failed to find workDetails")

# Let's find adminActions
admin_match = re.search(r'final Widget adminActions = Column\(([\s\S]*?)\n\s*\);\n', content)
if admin_match:
    admin_actions_code = admin_match.group(1)
    print("Found adminActions! Length:", len(admin_actions_code))
else:
    print("Failed to find adminActions")

