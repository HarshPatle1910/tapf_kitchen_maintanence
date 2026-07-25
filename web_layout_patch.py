import re

with open('lib/screens/ticket_detail_screen.dart', 'r') as f:
    content = f.read()

# 1. We'll find where `Widget build(BuildContext context)` starts.
build_index = content.find('  Widget build(BuildContext context) {')
if build_index == -1:
    print("Could not find build method")
    exit(1)

web_layout_code = """
  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.grey.shade500),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? "N/A" : value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebTabletLayout(
    BuildContext context, 
    AuthProvider authProv, 
    TicketProvider ticketProv,
    bool isAdmin,
    bool isAssignedWorker,
    bool canEditWorkDetails,
    bool readOnlyFields,
    bool showCameraBox,
    String activeKitchenName,
    String activeKitchenId,
    List<Map<String, dynamic>> availableEquipments,
    Widget adminActions,
    Widget workDetailsContent, // The old work details section
    Widget partsAndTools,      // Tools & spares
  ) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: Column(
          children: [
            // COMPACT HEADER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: navy.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.confirmation_number, color: navy, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isEditing ? (_localTicket!['ticket_no'] ?? 'Ticket') : "New Ticket",
                              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: navy),
                            ),
                            const SizedBox(width: 12),
                            if (isEditing) TicketStatusBanner(currentStatus: currentStatus, isCompact: true),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _titleController.text.isNotEmpty ? _titleController.text : "Enter a description below...",
                          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Actions right side
                  if (isEditing)
                    _buildContextualActionButton(isAdmin, isAssignedWorker, canEditWorkDetails)
                  else
                    _buildSubmitNewButton(),
                ],
              ),
            ),
            
            // MAIN CONTENT ROW (65/35 Split)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT COLUMN (65%)
                  Expanded(
                    flex: 65,
                    child: Container(
                      margin: const EdgeInsets.all(24),
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
                          // TABS
                          Container(
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                            ),
                            child: TabBar(
                              labelColor: navy,
                              unselectedLabelColor: Colors.grey.shade500,
                              indicatorColor: golden,
                              indicatorWeight: 3,
                              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                              tabs: const [
                                Tab(text: "General"),
                                Tab(text: "Work Details"),
                                Tab(text: "Photos"),
                                Tab(text: "History"),
                              ],
                            ),
                          ),
                          // TAB VIEWS
                          Expanded(
                            child: TabBarView(
                              children: [
                                // 1. GENERAL TAB
                                SingleChildScrollView(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildInfoRow("Raised On", _localTicket?['ticket_raised_time'] != null ? _formatDisplayDate(DateTime.tryParse(_localTicket!['ticket_raised_time'])?.toLocal()) : 'Unknown', icon: Icons.access_time),
                                      _buildInfoRow("Kitchen", activeKitchenName, icon: Icons.kitchen),
                                      _buildInfoRow("Area", _allAreas.isNotEmpty ? _allAreas.firstWhere((a) => a['id'].toString() == _selectedAreaId, orElse: () => {'display_name': 'Unknown'})['display_name'] ?? 'Unknown' : 'Unknown', icon: Icons.place),
                                      _buildInfoRow("Equipment", _selectedEquipments.isNotEmpty ? _selectedEquipments.first['display_name'] ?? 'Unknown' : 'Unknown', icon: Icons.precision_manufacturing),
                                      _buildInfoRow("Priority", _priority, icon: Icons.priority_high),
                                      _buildInfoRow("Category", _category, icon: Icons.category),
                                      _buildInfoRow("Breakdown", _formatDateTimeLocal(_breakdownTime), icon: Icons.timer),
                                      const SizedBox(height: 24),
                                      const Divider(),
                                      const SizedBox(height: 16),
                                      Text("Description", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                                      const SizedBox(height: 8),
                                      Text(_titleController.text, style: GoogleFonts.inter(fontSize: 15, color: navy)),
                                    ],
                                  ),
                                ),
                                
                                // 2. WORK DETAILS TAB
                                SingleChildScrollView(
                                  padding: const EdgeInsets.all(24),
                                  child: workDetailsContent,
                                ),
                                
                                // 3. PHOTOS TAB
                                SingleChildScrollView(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (isEditing) _buildMediaGallery(), // This handles before/after nicely
                                      if (showCameraBox) ...[
                                        const SizedBox(height: 24),
                                        Text(
                                          (!isEditing || !canEditWorkDetails) ? "Upload issue photo *" : "Upload Completion Photos *",
                                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 13),
                                        ),
                                        const SizedBox(height: 12),
                                        _buildImageUploader(canEditWorkDetails),
                                      ],
                                    ],
                                  ),
                                ),
                                
                                // 4. HISTORY TAB
                                SingleChildScrollView(
                                  padding: const EdgeInsets.all(24),
                                  child: isEditing ? TicketTimeline(ticket: _localTicket!) : const Text("No history available yet."),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // RIGHT SIDEBAR (35%)
                  Expanded(
                    flex: 35,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 24, right: 24, bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isEditing && isAdmin && (currentStatus == 'RAISED' || currentStatus == 'ASSIGNED')) ...[
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                              child: adminActions,
                            ),
                            const SizedBox(height: 20),
                          ],
                          
                          if (isEditing)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                              child: partsAndTools,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

"""

content = content[:build_index] + web_layout_code + content[build_index:]

with open('lib/screens/ticket_detail_screen.dart', 'w') as f:
    f.write(content)

print("Injected web layout helper.")
