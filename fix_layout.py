import re

with open('/tmp/ticket_detail_screen.dart', 'r') as f:
    content = f.read()

# First, let's fix the undefined variables in my injected _buildWebTabletLayout

# _descController.text -> (_localTicket?['description'] ?? 'No Description').toString()
content = content.replace("_descController.text", "(_localTicket?['description'] ?? 'No Description').toString()")

# _assignedWorkerId -> _localTicket?['ticket_assigned_to']
content = content.replace("_assignedWorkerId ?? \"Unassigned\"", "_localTicket?['ticket_assigned_to'] ?? \"Unassigned\"")

# navy -> const Color(0xFF0F172A)
# golden -> const Color(0xFFD4AF37)
content = content.replace("color: navy", "color: const Color(0xFF0F172A)")
content = content.replace("labelColor: navy", "labelColor: const Color(0xFF0F172A)")
content = content.replace("indicatorColor: golden", "indicatorColor: const Color(0xFFD4AF37)")

with open('/tmp/ticket_detail_screen.dart', 'w') as f:
    f.write(content)
