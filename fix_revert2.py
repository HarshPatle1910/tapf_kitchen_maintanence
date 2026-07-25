import re

with open('lib/screens/ticket_detail_screen.dart', 'r') as f:
    content = f.read()

content = re.sub(r'Widget build\(BuildContext context\) {', r'Widget _buildMobileLayout(BuildContext context) {', content)

with open('web_layout_dump.dart', 'r') as f:
    web_layout = f.read()

content = content.rstrip()[:-1] + "\n\n" + web_layout + "\n}\n"

with open('lib/screens/ticket_detail_screen.dart', 'w') as f:
    f.write(content)

