import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';

import 'ticket_detail_screen.dart';
import '../core/services/notification_service.dart';

// NEW WIDGET IMPORTS (Ensure these paths match your folder setup)
import '../widgets/ticket_card.dart';
import '../widgets/app_drawer.dart';
import '../widgets/filter_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color navy = Color(0xFF26538D);
  static const Color golden = Color(0xFFD4AF37);

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Map<String, dynamic>> _kitchenZones = [];

  @override
  void initState() {
    super.initState();
    NotificationService().initNotifications(

    );
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        context.read<TicketProvider>().fetchTickets(loadMore: true);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final ticketProvider = context.read<TicketProvider>();

      ticketProvider.initialize(authProvider.activeKitchenIds);

      if (ticketProvider.kitchenFilter == 'ALL' && authProvider.assignedKitchens.isNotEmpty) {
        final firstKitchenId = authProvider.assignedKitchens.first['id'].toString();
        ticketProvider.setFilters(kitchenId: firstKitchenId);
        _fetchZonesForFilter(firstKitchenId);
      } else {
        _fetchZonesForFilter(ticketProvider.kitchenFilter);
      }
    });
  }

  Future<void> _fetchZonesForFilter(String kitchenId) async {
    if (kitchenId == 'ALL' || kitchenId.isEmpty) {
      setState(() => _kitchenZones = []);
      return;
    }
    try {
      final response = await Supabase.instance.client
          .from('m_zone')
          .select('id, name')
          .eq('kitchen_id', kitchenId)
          .eq('status', true)
          .order('name');

      if (mounted) {
        setState(() {
          _kitchenZones = List<Map<String, dynamic>>.from(response);
          for (var z in _kitchenZones) { z['display_name'] = z['name']; }
        });
      }
    } catch (e) {
      debugPrint("Error fetching zones for filter: $e");
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Widget _buildStatCard(String label, int count, Color baseColor, String targetStatus, TicketProvider provider) {
    final isSelected = provider.statusFilter == targetStatus;
    return InkWell(
      onTap: () => provider.setFilters(status: targetStatus),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? baseColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? baseColor : Colors.grey.shade200, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(count.toString(), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: isSelected ? baseColor : navy)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: isSelected ? baseColor : Colors.grey.shade600, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticketProvider = context.watch<TicketProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isAdmin = authProvider.activeRole == 'admin';

    final bool hasActiveFilters = ticketProvider.priorityFilter != 'ALL' || ticketProvider.startDate != null || ticketProvider.zoneFilter != 'ALL' || ticketProvider.assignedToMeFilter;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        drawerScrimColor: Colors.black45,
        appBar: AppBar(
          elevation: 0, backgroundColor: Colors.white, foregroundColor: navy,
          title: Text("Maintenance Dashboard", style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          centerTitle: false,
        ),

        // NEW: Injected modular App Drawer
        drawer: AppDrawer(
            authProv: authProvider,
            ticketProv: ticketProvider,
            isAdmin: isAdmin,
            onKitchenChanged: _fetchZonesForFilter
        ),

        body: RefreshIndicator(
          color: golden,
          onRefresh: () => ticketProvider.refreshTickets(),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent, elevation: 0, floating: true, snap: true, automaticallyImplyLeading: false, toolbarHeight: 0,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(160),
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 16), width: double.infinity,
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

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white, borderRadius: BorderRadius.circular(12),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
                                  ),
                                  child: RawAutocomplete<Map<String, dynamic>>(
                                    textEditingController: _searchController, focusNode: _searchFocusNode,
                                    optionsBuilder: (TextEditingValue textEditingValue) {
                                      if (textEditingValue.text.isEmpty) return const Iterable<Map<String, dynamic>>.empty();
                                      final query = textEditingValue.text.toLowerCase();
                                      return ticketProvider.tickets.where((ticket) {
                                        final title = (ticket['title'] ?? '').toLowerCase();
                                        final no = (ticket['ticket_no'] ?? '').toLowerCase();
                                        return title.contains(query) || no.contains(query);
                                      });
                                    },
                                    displayStringForOption: (option) => option['ticket_no'] ?? '',
                                    onSelected: (selection) {
                                      _searchController.clear(); _searchFocusNode.unfocus();
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: selection)));
                                    },
                                    fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                                      return TextField(
                                        controller: textEditingController, focusNode: focusNode,
                                        onSubmitted: (value) { onFieldSubmitted(); context.read<TicketProvider>().setSearchQuery(value); },
                                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: navy),
                                        decoration: InputDecoration(
                                          hintText: "Search title or ticket #...", hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                          suffixIcon: textEditingController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey, size: 20), onPressed: () {
                                            textEditingController.clear(); context.read<TicketProvider>().setSearchQuery(''); focusNode.unfocus();
                                          }) : null,
                                          filled: true, fillColor: Colors.grey.shade50, contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: golden, width: 2)),
                                        ),
                                      );
                                    },
                                    optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<Map<String, dynamic>> onSelected, Iterable<Map<String, dynamic>> options) {
                                      return Align(
                                        alignment: Alignment.topLeft,
                                        child: Material(
                                          elevation: 4.0, borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            width: MediaQuery.of(context).size.width - 86,
                                            constraints: const BoxConstraints(maxHeight: 250),
                                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                                            child: ListView.separated(
                                              padding: EdgeInsets.zero, shrinkWrap: true, itemCount: options.length,
                                              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                                              itemBuilder: (BuildContext context, int index) {
                                                final option = options.elementAt(index);
                                                return ListTile(
                                                  title: Text(option['title'] ?? 'No Title', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: navy), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                  subtitle: Text(option['ticket_no'] ?? '#---', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                                                  trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                                                  onTap: () => onSelected(option),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Filter Trigger
                              InkWell(
                                onTap: () {
                                  _searchFocusNode.unfocus();
                                  showFilterBottomSheet(
                                      context: context,
                                      provider: ticketProvider,
                                      authProv: authProvider,
                                      kitchenZones: _kitchenZones
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: hasActiveFilters ? navy : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: hasActiveFilters ? navy : Colors.transparent),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
                                  ),
                                  child: Icon(Icons.tune, color: hasActiveFilters ? Colors.white : navy),
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

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      if (index == ticketProvider.tickets.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator(color: golden)),
                        );
                      }
                      return TicketCard(ticket: ticketProvider.tickets[index]); // NEW: Injected modular card
                    },
                    childCount: ticketProvider.tickets.length + (ticketProvider.isLoading ? 1 : 0),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: golden, foregroundColor: navy, elevation: 4,
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TicketDetailScreen())),
          icon: const Icon(Icons.add_rounded),
          label: Text("Raise Issue", style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ),
      ),
    );
  }
}