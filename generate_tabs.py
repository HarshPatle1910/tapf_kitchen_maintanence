import re

with open('lib/screens/ticket_detail_screen.dart', 'r') as f:
    content = f.read()

# We need to find the `return isWeb` block and replace it.
# The block starts at `return isWeb` and ends around `};` of the Builder.

regex = re.compile(r'(\s*)return isWeb\s*\?\s*Row\([\s\S]*?\)\s*:\s*Column\([\s\S]*?\);\s*\}\,\s*\)\,\s*\)\,\s*\)\,\s*bottomNavigationBar:', re.MULTILINE)

match = regex.search(content)
if not match:
    print("Could not find return isWeb block")
    exit(1)

indent = match.group(1)

new_return = indent + """
                Widget generalTab = SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: basicDetails,
                );

                Widget workTab = SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isEditing && (isAdmin || isAssignedWorker))
                        workDetails
                      else
                        Text("No work details available.", style: GoogleFonts.inter(color: Colors.grey.shade500)),
                    ],
                  ),
                );

                Widget photosTab = SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // We will just put a placeholder here or reuse existing image widgets if we had them separate
                      Text("Photos will appear here.", style: GoogleFonts.inter(color: Colors.grey.shade500)),
                    ],
                  ),
                );

                Widget historyTab = SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Text("History logs will appear here.", style: GoogleFonts.inter(color: Colors.grey.shade500)),
                );

                Widget rightSidebar = SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      adminActions,
                    ],
                  ),
                );

                return isWeb
                    ? DefaultTabController(
                        length: 4,
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 600),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 65,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TabBar(
                                        labelColor: const Color(0xFF0F172A),
                                        unselectedLabelColor: Colors.grey.shade500,
                                        indicatorColor: const Color(0xFFD4AF37),
                                        tabs: const [
                                          Tab(text: "General"),
                                          Tab(text: "Work Details"),
                                          Tab(text: "Photos"),
                                          Tab(text: "History"),
                                        ],
                                      ),
                                      SizedBox(
                                        height: 500, // Fixed height for TabBarView to prevent unbounded height errors
                                        child: TabBarView(
                                          children: [
                                            generalTab,
                                            workTab,
                                            photosTab,
                                            historyTab,
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 35,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: rightSidebar,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          basicDetails,
                          workDetails,
                          adminActions,
                          const SizedBox(height: 200),
                        ],
                      );
              },
            ),
          ),
        ),
        bottomNavigationBar:"""

content = content[:match.start()] + new_return + content[match.end():]

with open('lib/screens/ticket_detail_screen.dart', 'w') as f:
    f.write(content)

