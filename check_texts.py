import re

with open('lib/screens/ticket_detail_screen.dart', 'r') as f:
    content = f.read()

match = re.search(r'Widget _buildWebTabletLayout\(BuildContext context\) \{.*', content, re.DOTALL)
if match:
    layout_code = match.group(0)
    lines = layout_code.split('\n')
    for i, line in enumerate(lines):
        if 'Text(' in line:
            print(f"--- Line {i} ---")
            if i > 0: print(lines[i-1].strip())
            print(line.strip())
            if i < len(lines)-1: print(lines[i+1].strip())
            if i < len(lines)-2: print(lines[i+2].strip())
