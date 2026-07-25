import re

with open('lib/screens/ticket_detail_screen.dart', 'r') as f:
    content = f.read()

# Rename original build to _buildMobileLayout
content = re.sub(r'Widget build\(BuildContext context\) {', r'Widget _buildMobileLayout(BuildContext context) {', content)

# Read web layout dump
with open('web_layout_dump.dart', 'r') as f:
    web_layout = f.read()

# Replace the crossAxisAlignment in the web layout dump BEFORE inserting
web_layout = web_layout.replace('crossAxisAlignment: CrossAxisAlignment.start,', 'crossAxisAlignment: CrossAxisAlignment.stretch,')
web_layout = web_layout.replace("orElse: () => {'kitchen_name': 'Unknown'}", "orElse: () => <String, dynamic>{'kitchen_name': 'Unknown'}")
web_layout = web_layout.replace("orElse: () => {", "orElse: () => <String, dynamic>{")


# Insert it before the last brace
content = content.rstrip()[:-1] + "\n\n" + web_layout + "\n}\n"

with open('lib/screens/ticket_detail_screen.dart', 'w') as f:
    f.write(content)

