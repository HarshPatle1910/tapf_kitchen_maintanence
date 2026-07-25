import re

with open('lib/screens/ticket_detail_screen.dart', 'r') as f:
    content = f.read()

# Right before `final Widget workDetails = Column(`, we will define `basicDetails` again!
marker = "                final Widget workDetails = Column("
injection = """                final Widget basicDetails = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ticketHeader,
                    ticketGeneral,
                    ticketMedia,
                    ticketGeneral2,
                  ],
                );
                
"""
content = content.replace(marker, injection + marker)

with open('lib/screens/ticket_detail_screen.dart', 'w') as f:
    f.write(content)

print("Step 2 done")
