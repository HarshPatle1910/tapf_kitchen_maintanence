import re

with open('lib/screens/ticket_detail_screen.dart', 'r') as f:
    content = f.read()

basic_match = re.search(r'final Widget basicDetails = Column\([\s\S]*?children: \[\n\s*if \(isEditing\) \.\.\.\[([\s\S]*?)\],([\s\S]*?)\n\s*\],\n\s*\);', content)
if basic_match:
    ticket_details_code = basic_match.group(2)
    print("FIRST 200 CHARS:\n", ticket_details_code[:200])
    print("\nLAST 200 CHARS:\n", ticket_details_code[-200:])
