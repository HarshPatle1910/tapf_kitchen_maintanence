import re

with open('lib/screens/ticket_detail_screen.dart', 'r') as f:
    content = f.read()

# 1. Rename `Widget build(BuildContext context) {` to `Widget _buildMobileLayout(BuildContext context) {`
build_start = '  Widget build(BuildContext context) {'
content = content.replace(build_start, '  Widget _buildMobileLayout(BuildContext context) {', 1)

# 2. At the very end of the file, just before the final `}` of `_TicketDetailScreenState`, insert the new methods
end_marker = '}\n'
# To safely find the end of the class, we look for the last '}\n' in the file
last_brace = content.rfind('}\n')

new_methods = """
  Widget _buildInfoCard(String label, String value, {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: navy.withOpacity(0.6)),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? "N/A" : value,
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: navy),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebTabletLayout(BuildContext context) {
    final ticketProv = Provider.of<TicketProvider>(context, listen: false);
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final bool isAdmin = authProv.userRole == 'ADMIN' || authProv.userRole == 'SUPER_ADMIN';
    final bool isAssignedWorker = _localTicket?['ticket_assigned_to'] == authProv.userId;
    final bool canEditWorkDetails = isEditing && isAssignedWorker && currentStatus == 'IN_PROGRESS';
    final bool showCameraBox = isEditing && (currentStatus == 'RAISED' || currentStatus == 'IN_PROGRESS');
    
    final String activeKitchenId = authProv.activeKitchenId ?? '';
    final String activeKitchenName = authProv.assignedKitchens.firstWhere(
      (k) => k['id'].toString() == activeKitchenId,
      orElse: () => {'kitchen_name': 'Unknown'},
    )['kitchen_name'] ?? 'Unknown';

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: Column(
          children: [
            // COMPACT HEADER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: navy.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.confirmation_number, color: navy, size: 28),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(isEditing ? (_localTicket!['ticket_no'] ?? 'Ticket') : "New Ticket", style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: navy)),
                            const SizedBox(width: 16),
                            if (isEditing) TicketStatusBanner(currentStatus: currentStatus, isCompact: true),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(_titleController.text.isNotEmpty ? _titleController.text : "No description provided", style: GoogleFonts.inter(fontSize: 15, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // MAIN TWO-COLUMN CONTENT
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT COLUMN (65%)
                    Expanded(
                      flex: 65,
                      child: Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
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
                            Expanded(
                              child: TabBarView(
                                children: [
                                  // GENERAL TAB
                                  SingleChildScrollView(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildInfoCard("Ticket Title / Description", _titleController.text, icon: Icons.description),
                                        Row(
                                          children: [
                                            Expanded(child: _buildInfoCard("Priority", _priority, icon: Icons.priority_high)),
                                            const SizedBox(width: 16),
                                            Expanded(child: _buildInfoCard("Category", _category, icon: Icons.category)),
                                          ],
                                        ),
                                        _buildInfoCard("Target Kitchen", activeKitchenName, icon: Icons.kitchen),
                                        Row(
                                          children: [
                                            Expanded(child: _buildInfoCard("Area", _allAreas.isNotEmpty ? _allAreas.firstWhere((a) => a['id'].toString() == _selectedAreaId, orElse: () => {'display_name': 'Unknown'})['display_name'] ?? 'Unknown' : 'Unknown', icon: Icons.place)),
                                            const SizedBox(width: 16),
                                            Expanded(child: _buildInfoCard("Equipment", _selectedEquipments.isNotEmpty ? _selectedEquipments.first['display_name'] ?? 'Unknown' : 'Unknown', icon: Icons.precision_manufacturing)),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Expanded(child: _buildInfoCard("Raised On", _localTicket?['ticket_raised_time'] != null ? _formatDisplayDate(DateTime.tryParse(_localTicket!['ticket_raised_time'])?.toLocal()) : 'Unknown', icon: Icons.calendar_today)),
                                            const SizedBox(width: 16),
                                            Expanded(child: _buildInfoCard("Breakdown Time", _formatDateTimeLocal(_breakdownTime), icon: Icons.timer)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // WORK DETAILS TAB
                                  SingleChildScrollView(
                                    padding: const EdgeInsets.all(24),
                                    child: (currentStatus == 'IN_PROGRESS' || currentStatus == 'COMPLETED' || currentStatus == 'VERIFIED')
                                        ? Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              TicketFormFields.buildTextField(
                                                ctrl: _causeController,
                                                label: "Cause of Issue *",
                                                icon: Icons.report_problem_outlined,
                                                maxLines: 4,
                                                isReadOnly: !canEditWorkDetails,
                                                isRequired: canEditWorkDetails,
                                                textCapitalization: TextCapitalization.sentences,
                                              ),
                                              const SizedBox(height: 24),
                                              TicketFormFields.buildTextField(
                                                ctrl: _actionTakenController,
                                                label: "Action Taken *",
                                                icon: Icons.handyman,
                                                maxLines: 4,
                                                isReadOnly: !canEditWorkDetails,
                                                isRequired: canEditWorkDetails,
                                                textCapitalization: TextCapitalization.sentences,
                                              ),
                                            ],
                                          )
                                        : Text("Work details are only available when the ticket is in progress.", style: GoogleFonts.inter(color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
                                  ),
                                  
                                  // PHOTOS TAB
                                  SingleChildScrollView(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (isEditing) _buildMediaGallery(),
                                        if (showCameraBox) ...[
                                          const SizedBox(height: 24),
                                          const Divider(),
                                          const SizedBox(height: 24),
                                          Text((!isEditing || !canEditWorkDetails) ? "Upload issue photo *" : "Upload Completion Photos *", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 14)),
                                          const SizedBox(height: 12),
                                          _buildImageUploader(canEditWorkDetails),
                                        ],
                                      ],
                                    ),
                                  ),
                                  
                                  // HISTORY TAB
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
                    
                    const SizedBox(width: 24),
                    
                    // RIGHT SIDEBAR (35%)
                    Expanded(
                      flex: 35,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Admin Actions
                            if (isEditing && isAdmin && (currentStatus == 'RAISED' || currentStatus == 'ASSIGNED')) ...[
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Assign Worker", style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: navy)),
                                    const SizedBox(height: 16),
                                    Consumer<TicketProvider>(
                                      builder: (context, provider, child) {
                                        final eligibleWorkers = provider.eligibleWorkers;
                                        return DropdownButtonFormField<String>(
                                          value: _selectedWorker,
                                          isExpanded: true,
                                          dropdownColor: Colors.white,
                                          decoration: InputDecoration(
                                            labelText: "Select Worker",
                                            prefixIcon: const Icon(Icons.engineering_outlined, color: Colors.grey),
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                                          ),
                                          items: eligibleWorkers.map((w) => DropdownMenuItem<String>(value: w['id'].toString(), child: Text(w['display_name'].toString()))).toList(),
                                          onChanged: (val) => setState(() => _selectedWorker = val),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                            
                            // Tools & Spares
                            if (isEditing)
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Tools Checked Out", style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: navy)),
                                    const SizedBox(height: 16),
                                    if (canEditWorkDetails) ...[
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildAutocomplete(
                                              hint: "Search Required Tool",
                                              icon: Icons.plumbing,
                                              controller: _toolSearchController,
                                              focusNode: _toolFocusNode,
                                              options: _availableTools,
                                              isDisabled: false,
                                              onSelected: (val) => setState(() => _currentlySelectedToolToAdd = val),
                                              onCleared: () => setState(() => _currentlySelectedToolToAdd = null),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(10)),
                                            child: IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: _addToolToTicket),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    if (_usedTools.isEmpty)
                                      Text("No tools added", style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13, fontStyle: FontStyle.italic))
                                    else
                                      ..._usedTools.map((tool) {
                                        final bool isReturned = tool['returned'] ?? false;
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                                          child: Row(
                                            children: [
                                              Icon(isReturned ? Icons.check_circle : Icons.handyman, size: 16, color: isReturned ? Colors.green : navy),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text(tool['tool_name'], style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: isReturned ? Colors.green.shade800 : navy))),
                                              if (canEditWorkDetails)
                                                IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18), onPressed: () => _removeTool(tool)),
                                            ],
                                          ),
                                        );
                                      }),
                                      
                                    if (currentStatus == 'IN_PROGRESS' && isAssignedWorker && _usedTools.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade300)),
                                        child: CheckboxListTile(
                                          title: Text("I have returned all tools", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.orange.shade900, fontSize: 14)),
                                          value: _toolsReturned,
                                          activeColor: Colors.green.shade700,
                                          onChanged: (val) => setState(() => _toolsReturned = val ?? false),
                                        ),
                                      ),
                                    ],
                                    
                                    const SizedBox(height: 32),
                                    const Divider(),
                                    const SizedBox(height: 24),
                                    
                                    Text("Spares Used", style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: navy)),
                                    const SizedBox(height: 16),
                                    if (canEditWorkDetails) ...[
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: _buildAutocomplete(
                                              hint: "Search Spare",
                                              icon: Icons.build_circle,
                                              controller: _spareSearchController,
                                              focusNode: _spareFocusNode,
                                              options: _availableSpares,
                                              isDisabled: false,
                                              onSelected: (val) => setState(() => _currentlySelectedSpareToAdd = val),
                                              onCleared: () => setState(() => _currentlySelectedSpareToAdd = null),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 1,
                                            child: TextFormField(
                                              controller: _spareQtyController,
                                              keyboardType: TextInputType.number,
                                              decoration: InputDecoration(
                                                hintText: "Qty",
                                                filled: true,
                                                fillColor: Colors.grey.shade50,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(10)),
                                            child: IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: _addSpareToTicket),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    if (_usedSpares.isEmpty)
                                      Text("No spares added", style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13, fontStyle: FontStyle.italic))
                                    else
                                      ..._usedSpares.map((item) {
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.build, size: 16, color: navy),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text(item['spare_name'], style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: navy))),
                                              Text("x${item['quantity']}", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: navy)),
                                              if (canEditWorkDetails)
                                                IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18), onPressed: () => _removeSpare(item)),
                                            ],
                                          ),
                                        );
                                      }),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
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

  @override
  Widget build(BuildContext context) {
    final bool isMobileDevice = MediaQuery.of(context).size.width < 768;
    if (!isMobileDevice) {
      return _buildWebTabletLayout(context);
    }
    return _buildMobileLayout(context);
  }
"""

content = content[:last_brace] + new_methods + content[last_brace:]

with open('lib/screens/ticket_detail_screen.dart', 'w') as f:
    f.write(content)

print("Rewrote layout correctly")
