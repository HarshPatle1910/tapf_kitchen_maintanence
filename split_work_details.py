import re

with open('lib/screens/ticket_detail_screen.dart', 'r') as f:
    content = f.read()

# 1. Find the workDetails definition
work_details_start = "                final Widget workDetails = Column("
work_details_index = content.find(work_details_start)
if work_details_index == -1:
    print("Could not find workDetails")
    exit(1)

# We want to change the workDetails definition to two separate widgets:
# 1. workDetailsContent
# 2. partsAndTools

old_work_details = """                final Widget workDetails = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentStatus == 'IN_PROGRESS' ||
                        currentStatus == 'COMPLETED' ||
                        currentStatus == 'VERIFIED') ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Work Details",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: navy,
                          ),
                        ),
                        const Divider(height: 24),

                        TicketFormFields.buildTextField(
                          ctrl: _causeController,
                          label: "Cause of Issue *",
                          icon: Icons.report_problem_outlined,
                          maxLines: 3,
                          isReadOnly: !canEditWorkDetails,
                          isRequired: canEditWorkDetails,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 16),

                        TicketFormFields.buildTextField(
                          ctrl: _actionTakenController,
                          label: "Action Taken *",
                          icon: Icons.handyman,
                          maxLines: 3,
                          isReadOnly: !canEditWorkDetails,
                          isRequired: canEditWorkDetails,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 24),"""

new_work_details = """                final Widget workDetailsContent = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentStatus == 'IN_PROGRESS' || currentStatus == 'COMPLETED' || currentStatus == 'VERIFIED') ...[
                      TicketFormFields.buildTextField(
                        ctrl: _causeController,
                        label: "Cause of Issue *",
                        icon: Icons.report_problem_outlined,
                        maxLines: 3,
                        isReadOnly: !canEditWorkDetails,
                        isRequired: canEditWorkDetails,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 16),
                      TicketFormFields.buildTextField(
                        ctrl: _actionTakenController,
                        label: "Action Taken *",
                        icon: Icons.handyman,
                        maxLines: 3,
                        isReadOnly: !canEditWorkDetails,
                        isRequired: canEditWorkDetails,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ] else ...[
                      Text("Work details are only available when ticket is in progress or completed.", style: GoogleFonts.inter(color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                    ]
                  ],
                );
                
                final Widget partsAndTools = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentStatus == 'IN_PROGRESS' || currentStatus == 'COMPLETED' || currentStatus == 'VERIFIED') ...["""

content = content.replace(old_work_details, new_work_details)

# 2. Fix the closing brackets for workDetails that were just opened
# The end of workDetails has:
old_work_details_end = """                  ],
                );

                final Widget adminActions = Column("""

new_work_details_end = """                  ],
                );

                final Widget workDetails = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentStatus == 'IN_PROGRESS' || currentStatus == 'COMPLETED' || currentStatus == 'VERIFIED') ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Work Details", style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: navy)),
                            const Divider(height: 24),
                            workDetailsContent,
                            const SizedBox(height: 24),
                            partsAndTools,
                          ],
                        ),
                      )
                    ]
                  ]
                );

                final Widget adminActions = Column("""

content = content.replace(old_work_details_end, new_work_details_end)

# 3. Update the return layout
old_return = """                final double screenWidth = MediaQuery.of(context).size.width;
                final bool isDesktop = screenWidth >= 1100;
                final bool isTablet = screenWidth >= 768 && screenWidth < 1100;

                if (isDesktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 10,
                        child: basicDetails,
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 12,
                        child: workDetails,
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 9,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            mediaDetails,
                            adminActions,
                            const SizedBox(height: 200),
                          ],
                        ),
                      ),
                    ],
                  );
                } else if (isTablet) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            basicDetails,
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            mediaDetails,
                            workDetails,
                            adminActions,
                            const SizedBox(height: 200),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      basicDetails,
                      mediaDetails,
                      workDetails,
                      adminActions,
                      const SizedBox(height: 200),
                    ],
                  );
                }"""

new_return = """                final double screenWidth = MediaQuery.of(context).size.width;
                final bool isDesktop = screenWidth >= 1100;
                final bool isTablet = screenWidth >= 768 && screenWidth < 1100;

                if (isDesktop || isTablet) {
                  return _buildWebTabletLayout(
                    context, 
                    authProv, 
                    ticketProv, 
                    isAdmin, 
                    isAssignedWorker, 
                    canEditWorkDetails, 
                    readOnlyFields, 
                    showCameraBox, 
                    activeKitchenName, 
                    activeKitchenId, 
                    availableEquipments, 
                    adminActions, 
                    workDetailsContent, 
                    partsAndTools,
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      basicDetails,
                      mediaDetails,
                      workDetails,
                      adminActions,
                      const SizedBox(height: 200),
                    ],
                  );
                }"""

content = content.replace(old_return, new_return)

with open('lib/screens/ticket_detail_screen.dart', 'w') as f:
    f.write(content)

print("Split workDetails logic and updated layout.")
