import re

with open('lib/screens/home_screen.dart', 'r') as f:
    content = f.read()

# 1. We need to extract the SearchBar and Filter into a helper method.
# The search bar and filter code is inside the SliverAppBar bottom widget.
# Let's extract the whole Row containing Search and Filter:

search_filter_regex = re.compile(r'(Padding\(\s*padding: const EdgeInsets\.symmetric\(horizontal: 16\),\s*child: Row\(\s*children: \[\s*Expanded\(\s*child: Container\(\s*decoration:.*?)(?=\s*\]\,\s*\)\,\s*\)\,\s*\]\,\s*\)\,\s*\)\,\s*\)\,\s*\)\,\s*SliverPadding\()', re.DOTALL)

match = search_filter_regex.search(content)
if match:
    search_filter_code = match.group(1)
else:
    print("Failed to find Search and Filter code.")
    exit(1)

helper_method = """
  Widget _buildSearchBarAndFilter(TicketProvider ticketProvider, AuthProvider authProv, bool hasActiveFilters) {
    return """ + search_filter_code + """;
  }
"""

# Let's write the modified file manually or through regex.
# Actually, the entire _HomeTicketViewState is manageable. 
# Let's use Python to replace exactly what we need.

# First, replace the body of the Scaffold in _HomeTicketView
body_regex = re.compile(r'(body: Center\(\s*child: ConstrainedBox\(\s*constraints: const BoxConstraints\(maxWidth: 1200\),\s*child: RefreshIndicator\(\s*color: golden,\s*backgroundColor: Colors\.white,\s*onRefresh: \(\) => ticketProvider\.refreshTickets\(\),\s*child: )(CustomScrollView\(.*?)\)\,\s*\)\,\s*\)\,\s*floatingActionButton:', re.DOTALL)

body_match = body_regex.search(content)
if body_match:
    prefix = body_match.group(1)
    custom_scroll_view = body_match.group(2)
    
    new_body = prefix + """
              isWeb 
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: WebTicketTable(
                        tickets: ticketProvider.tickets,
                        isLoading: ticketProvider.isLoading,
                      ),
                    )
                  : """ + custom_scroll_view + """
            ),
          ),
        ),
        floatingActionButton:"""
    content = content[:body_match.start()] + new_body + content[body_match.end():]
else:
    print("Failed to replace body.")
    exit(1)

# Now update the AppBar to add actions for Web
appbar_regex = re.compile(r'(appBar: AppBar\(\s*backgroundColor: Colors\.white,\s*elevation: 0,\s*toolbarHeight: 75,\s*title: Row\((?:[^)(]+|\((?:[^)(]+|\([^)(]*\))*\))*\)\,\s*)(\),)', re.DOTALL)
appbar_match = appbar_regex.search(content)
if appbar_match:
    appbar_prefix = appbar_match.group(1)
    
    new_appbar = appbar_prefix + """
          actions: isWeb ? [
            SizedBox(
              width: 450,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  children: [
                    Expanded(child: _buildStatCard("Total", ticketProvider.total, Colors.blueGrey, 'ALL', ticketProvider)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildStatCard("To Do", ticketProvider.toDo, Colors.redAccent, 'TO DO', ticketProvider)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildStatCard("WIP", ticketProvider.inProgress, Colors.orange, 'IN PROGRESS', ticketProvider)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildStatCard("Done", ticketProvider.completed, Colors.green, 'COMPLETED', ticketProvider)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildStatCard("Verified", ticketProvider.verified, Colors.teal, 'VERIFIED', ticketProvider)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 350,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: _buildSearchBarAndFilter(ticketProvider, authProv, hasActiveFilters),
              ),
            ),
            const SizedBox(width: 16),
          ] : null,
        ),"""
    content = content[:appbar_match.start()] + new_appbar + content[appbar_match.end():]
else:
    print("Failed to replace AppBar.")
    exit(1)

# Finally, insert the helper method at the end of _HomeTicketViewState
# Look for the last '}' of the class. It's before the end of the file.
# The class ends after `_buildStatCard` method.
stat_card_regex = re.compile(r'(Widget _buildStatCard.*?\}\s*\n)\}\s*$', re.DOTALL)
stat_match = stat_card_regex.search(content)
if stat_match:
    content = content[:stat_match.start()] + stat_match.group(1) + helper_method + "}\n"
else:
    print("Failed to insert helper method.")
    exit(1)

with open('lib/screens/home_screen.dart', 'w') as f:
    f.write(content)

print("Successfully modified home_screen.dart")
