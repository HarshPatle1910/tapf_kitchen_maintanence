
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ResponsiveSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isFixed;
  final VoidCallback onToggleFixed;
  final List<SidebarItem> items;
  static const Color navy = Color(0xFF26538D);

  const ResponsiveSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isFixed,
    required this.onToggleFixed,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isFixed ? 220 : 72,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Toggle Button
          Align(
            alignment: isFixed ? Alignment.centerRight : Alignment.center,
            child: Padding(
              padding: isFixed ? const EdgeInsets.only(right: 12.0) : EdgeInsets.zero,
              child: IconButton(
                icon: Icon(isFixed ? Icons.menu_open : Icons.menu, color: navy),
                onPressed: onToggleFixed,
                tooltip: isFixed ? 'Collapse Sidebar' : 'Expand Sidebar',
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Navigation Items
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = selectedIndex == index;
                
                return InkWell(
                  onTap: () => onItemSelected(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? navy.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: isFixed ? MainAxisAlignment.start : MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: isSelected ? navy : Colors.grey.shade500,
                          size: 24,
                        ),
                        if (isFixed) ...[
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              item.label,
                              style: GoogleFonts.inter(
                                color: isSelected ? navy : Colors.grey.shade700,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SidebarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  SidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
