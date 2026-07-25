import re

with open('lib/screens/ticket_detail_screen.dart', 'r') as f:
    content = f.read()

# Replace Widget build with _buildMobileLayout
content = content.replace("  Widget build(BuildContext context) {", "  Widget _buildMobileLayout(BuildContext context) {", 1)

# Now, find the end of the class which is the last '}'
last_brace_index = content.rfind('}')

# The code to inject
injection = """
  Widget _buildInfoCard(String label, dynamic value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: Colors.blueGrey),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (value is Widget)
            value
          else
            Text(
              value.toString(),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWebTabletLayout(BuildContext context) {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final bool isAdmin = authProv.activeRole == 'ADMIN' || authProv.activeRole == 'SUPER_ADMIN';
    final bool isAssignedWorker = _localTicket?['ticket_assigned_to'] == authProv.currentUserId;
    final bool canEditWorkDetails = isEditing && isAssignedWorker && currentStatus == 'IN_PROGRESS';
    final bool showCameraBox = isEditing &&
        isAssignedWorker &&
        (currentStatus == 'RAISED' || currentStatus == 'IN_PROGRESS');

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: navy),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            isEditing
                ? (_localTicket!['ticket_no']?.toString() ?? 'Ticket')
                : "New Ticket",
            style: GoogleFonts.inter(
              color: navy,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            if (isEditing)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildStatusChip(currentStatus ?? 'UNKNOWN'),
              )
          ],
        ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // LEFT COLUMN (65%)
            Expanded(
              flex: 65,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                        ),
                        child: TabBar(
                          labelColor: navy,
                          unselectedLabelColor: Colors.grey.shade500,
                          indicatorColor: golden,
                          tabs: const [
                            Tab(text: "General"),
                            Tab(text: "Work Details"),
                            Tab(text: "Photos"),
                            Tab(text: "History"),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // GENERAL TAB
                            SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoCard("Title", _titleController.text, icon: Icons.title),
                                  const SizedBox(height: 16),
                                  _buildInfoCard("Description", _descController.text, icon: Icons.description),
                                  const SizedBox(height: 16),
                                  _buildInfoCard("Priority", _priority, icon: Icons.priority_high),
                                ],
                              ),
                            ),
                            // WORK DETAILS TAB
                            SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isEditing) ...[
                                    Text("Work Actions", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: navy)),
                                    const SizedBox(height: 16),
                                    if (isAdmin || isAssignedWorker)
                                      _buildStatusDropdown(isAdmin, isAssignedWorker),
                                    const SizedBox(height: 16),
                                    if (canEditWorkDetails)
                                      _buildToolsAndSparesSection(),
                                  ] else
                                    Text("Available after creating ticket.", style: GoogleFonts.inter(color: Colors.grey.shade500)),
                                ],
                              ),
                            ),
                            // PHOTOS TAB
                            SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (showCameraBox) ...[
                                    _buildImagePickerBox(),
                                    const SizedBox(height: 16),
                                  ],
                                  if (isEditing)
                                    _buildExistingImagesSection(),
                                ],
                              ),
                            ),
                            // HISTORY TAB
                            SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isEditing)
                                    _buildTimeline()
                                  else
                                    Text("No history yet.", style: GoogleFonts.inter(color: Colors.grey.shade500)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // RIGHT COLUMN (35%)
            Expanded(
              flex: 35,
              child: Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 16, right: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Assignment", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: navy)),
                        const SizedBox(height: 16),
                        _buildInfoCard("Worker", _assignedWorkerId ?? "Unassigned", icon: Icons.person),
                        const SizedBox(height: 24),
                        Text("Tools & Spares", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: navy)),
                        const SizedBox(height: 16),
                        _buildUsedToolsSummary(),
                        const SizedBox(height: 16),
                        _buildUsedSparesSummary(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: isEditing
            ? _buildContextualActionButton(isAdmin, isAssignedWorker, canEditWorkDetails)
            : _buildSubmitNewButton(),
      ),
    );
  }

  Widget _buildUsedToolsSummary() {
    if (_usedTools.isEmpty) return Text("No tools", style: GoogleFonts.inter(color: Colors.grey.shade500));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _usedTools.map((t) => Text("- ${t['tool_name']}", style: GoogleFonts.inter(color: navy))).toList(),
    );
  }

  Widget _buildUsedSparesSummary() {
    if (_usedSpares.isEmpty) return Text("No spares", style: GoogleFonts.inter(color: Colors.grey.shade500));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _usedSpares.map((s) => Text("- ${s['spare_name']} (x${s['quantity']})", style: GoogleFonts.inter(color: navy))).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobileDevice = MediaQuery.of(context).size.width < 768;
    if (!isMobileDevice) {
      return _buildWebTabletLayout(context);
    }
    return _buildMobileLayout(context);
  }
"""

content = content[:last_brace_index] + injection + "\n}\n"

with open('lib/screens/ticket_detail_screen.dart', 'w') as f:
    f.write(content)
