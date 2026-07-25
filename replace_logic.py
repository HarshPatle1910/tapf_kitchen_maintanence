import re

with open('lib/screens/ticket_detail_screen.dart', 'r') as f:
    content = f.read()

builder_pattern = re.compile(r'(child:\s*Builder\(\s*builder:\s*\(context\)\s*\{\s*)(.*?)(^\s*\},?\n\s*\),?\n\s*\),?\n\s*\),?\n\s*bottomNavigationBar:)', re.DOTALL | re.MULTILINE)
match = builder_pattern.search(content)

if not match:
    print("Could not find the Builder block.")
    exit(1)

prefix = match.group(1)
builder_body = match.group(2)
suffix = match.group(3)

# 1. We want to extract the different pieces from builder_body.

# basicDetails extraction
basic_details_match = re.search(r'final Widget basicDetails = Column\(\s*crossAxisAlignment: CrossAxisAlignment\.start,\s*children: \[(.*?)\],\s*\);', builder_body, re.DOTALL)
basic_children = basic_details_match.group(1) if basic_details_match else ""

# workDetails extraction
work_details_match = re.search(r'final Widget workDetails = Column\(\s*crossAxisAlignment: CrossAxisAlignment\.start,\s*children: \[(.*?)\],\s*\);', builder_body, re.DOTALL)
work_children = work_details_match.group(1) if work_details_match else ""

# adminActions extraction
admin_actions_match = re.search(r'final Widget adminActions = Column\(\s*crossAxisAlignment: CrossAxisAlignment\.start,\s*children: \[(.*?)\],\s*\);', builder_body, re.DOTALL)
admin_children = admin_actions_match.group(1) if admin_actions_match else ""

# Now, let's carefully isolate the components from `basic_children`.
# 1. Header (Status, Raised On, Timeline)
header_pattern = re.compile(r'(if \(isEditing\) \.\.\.\[.*?TicketTimeline\(ticket: _localTicket!\),\s*const SizedBox\(height: 12\),\s*\]\,)', re.DOTALL)
header_match = header_pattern.search(basic_children)
header_code = header_match.group(1) if header_match else ""

# 2. Inside the large Container in basic_children
container_pattern = re.compile(r'Container\(\s*padding: const EdgeInsets\.symmetric\([\s\S]*?child: Column\([\s\S]*?children: \[(.*?)\],\s*\),\s*\)', re.DOTALL)
container_match = container_pattern.search(basic_children)
container_code = container_match.group(1) if container_match else ""

# The container_code has:
# - Target Kitchen
# - Media Gallery & Camera Box (Column)
# - Breakdown Time
# - Area
# - Equipment
# - Title / Description
# - Priority
# - Category

# Let's extract Media Gallery & Camera Box out of container_code
media_pattern = re.compile(r'(Column\(\s*crossAxisAlignment: CrossAxisAlignment\.start,\s*children: \[\s*if \(isEditing\) _buildMediaGallery\(\),\s*if \(showCameraBox\) \.\.\.\[[\s\S]*?\]\,?\s*\]\,?\s*\)\,?\s*const SizedBox\(height: 12\)\,?)', re.DOTALL)
media_match = media_pattern.search(container_code)
media_code = media_match.group(1) if media_match else ""

# Remove media from container_code to get ticket_info_code
ticket_info_code = container_code.replace(media_code, "") if media_code else container_code

# In workDetails, we have a large Container containing "Work Details" header, Cause, Action, Tools checked out, Spares used.
# And then the CheckboxListTiles for worker / admin tool return.
# Let's extract the inside of the workDetails Container.
work_container_match = container_pattern.search(work_children)
work_container_code = work_container_match.group(1) if work_container_match else ""

# Let's split work_container_code into (Work Details text, Cause, Action) and (Tools, Spares)
# It starts with Text("Work Details") and Divider.
parts_tools_pattern = re.compile(r'(Text\(\s*"Tools Checked Out"[\s\S]*)', re.DOTALL)
parts_match = parts_tools_pattern.search(work_container_code)
parts_code = parts_match.group(1) if parts_match else ""

# The rest is resolution code
resolution_code = work_container_code.replace(parts_code, "") if parts_code else work_container_code

# The checkboxes are outside the container in work_children
checkboxes_pattern = re.compile(r'(if \(currentStatus == \'IN_PROGRESS\'[\s\S]*)', re.DOTALL)
checkboxes_match = checkboxes_pattern.search(work_children)
checkboxes_code = checkboxes_match.group(1) if checkboxes_match else ""


# Let's form the new builder body
new_builder = f"""
                final double screenWidth = MediaQuery.of(context).size.width;
                final bool isDesktop = screenWidth >= 1100;
                final bool isTablet = screenWidth >= 768 && screenWidth < 1100;
                final bool isMobile = screenWidth < 768;

                Widget _buildCard(String title, List<Widget> children, {{bool noPadding = false}}) {{
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: noPadding ? EdgeInsets.zero : const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title.isNotEmpty) ...[
                          Text(
                            title,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: navy,
                            ),
                          ),
                          const Divider(height: 24),
                        ],
                        ...children,
                      ],
                    ),
                  );
                }}

                final Widget ticketInfoCard = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    {header_code}
                    _buildCard("Ticket Information", [
                      {ticket_info_code}
                    ]),
                  ],
                );

                final Widget workDetailsCard = currentStatus == 'IN_PROGRESS' || currentStatus == 'COMPLETED' || currentStatus == 'VERIFIED'
                    ? _buildCard("Work Details & Resolution", [
                        {resolution_code}
                      ])
                    : const SizedBox.shrink();

                final Widget partsAndToolsCard = currentStatus == 'IN_PROGRESS' || currentStatus == 'COMPLETED' || currentStatus == 'VERIFIED'
                    ? _buildCard("Parts & Tools", [
                        {parts_code}
                        {checkboxes_code}
                      ])
                    : const SizedBox.shrink();

                final Widget mediaAdminCard = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isEditing || showCameraBox)
                      _buildCard("Media", [
                        {media_code}
                      ]),
                    if (isEditing && isAdmin && (currentStatus == 'RAISED' || currentStatus == 'ASSIGNED'))
                      _buildCard("Admin Actions", [
                        {admin_children}
                      ]),
                  ],
                );

                if (isDesktop) {{
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 10,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ticketInfoCard,
                            mediaAdminCard,
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 12,
                        child: workDetailsCard,
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 10,
                        child: partsAndToolsCard,
                      ),
                    ],
                  );
                }} else if (isTablet) {{
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ticketInfoCard,
                            partsAndToolsCard,
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            workDetailsCard,
                            mediaAdminCard,
                          ],
                        ),
                      ),
                    ],
                  );
                }} else {{
                  // Mobile
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ticketInfoCard,
                      workDetailsCard,
                      partsAndToolsCard,
                      mediaAdminCard,
                      const SizedBox(height: 100),
                    ],
                  );
                }}
"""

new_content = content[:match.start(2)] + new_builder + content[match.end(2):]

with open('lib/screens/ticket_detail_screen.dart', 'w') as f:
    f.write(new_content)

print("Successfully replaced builder body.")
