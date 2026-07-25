import re

with open('lib/screens/home_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("import '../widgets/ticket/web_ticket_table.dart';", "import '../widgets/web_ticket_table.dart';")
content = content.replace("child: WebTicketTable(\n              ticketProvider: ticketProvider,\n            ),", """child: WebTicketTable(
              tickets: ticketProvider.tickets,
              isLoading: ticketProvider.isLoading,
              onLoadMore: ticketProvider.tickets.length < ticketProvider.currentFilterTotal 
                  ? () => ticketProvider.fetchMoreTickets() 
                  : null,
            ),""")

with open('lib/screens/home_screen.dart', 'w') as f:
    f.write(content)

