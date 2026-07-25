import re

with open('lib/screens/ticket_detail_screen.dart', 'r') as f:
    content = f.read()

old_return = """                return isWeb
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: basicDetails,
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                workDetails,
                                adminActions,
                                const SizedBox(height: 200),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          basicDetails,
                          workDetails,
                          adminActions,
                          const SizedBox(height: 200),
                        ],
                      );"""

new_return = """                final double screenWidth = MediaQuery.of(context).size.width;
                final bool isMobileDevice = screenWidth < 768;
                
                final Widget mediaDetails = const SizedBox.shrink(); // Legacy definition

                if (!isMobileDevice) {
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
                      workDetailsContent,
                      partsAndTools,
                      adminActions,
                      const SizedBox(height: 200),
                    ],
                  );
                }"""

content = content.replace(old_return, new_return)

with open('lib/screens/ticket_detail_screen.dart', 'w') as f:
    f.write(content)

print("Fixed return block")
