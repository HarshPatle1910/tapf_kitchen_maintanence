import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RaiseTicketScreen extends ConsumerStatefulWidget {
  const RaiseTicketScreen({super.key});

  @override
  ConsumerState<RaiseTicketScreen> createState() => _RaiseTicketScreenState();
}

class _RaiseTicketScreenState extends ConsumerState<RaiseTicketScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form State
  String? selectedKitchenId; // Filtered to user's kitchens
  String? selectedEquipmentId;
  String? selectedCategoryId;
  String selectedPriority = 'MEDIUM';
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Raise New Issue")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Kitchen Selector (Filtered by RLS/User Assignment)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Kitchen *", border: OutlineInputBorder()),
                items: const [DropdownMenuItem(value: "k-1", child: Text("Main Kitchen"))], // Fetch from user_kitchens
                onChanged: (val) => setState(() => selectedKitchenId = val),
                validator: (val) => val == null ? "Required" : null,
              ),
              const SizedBox(height: 16),

              // 2. Equipment Selector (Filtered by Kitchen ID)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Equipment (Optional)", border: OutlineInputBorder()),
                items: const [DropdownMenuItem(value: "e-1", child: Text("Industrial Oven #4"))], // Fetch where kitchen_id = selectedKitchenId
                onChanged: (val) => setState(() => selectedEquipmentId = val),
              ),
              const SizedBox(height: 16),

              // 3. Category & Priority
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Category *", border: OutlineInputBorder()),
                      items: const [DropdownMenuItem(value: "c-1", child: Text("Electrical"))],
                      onChanged: (val) => selectedCategoryId = val,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedPriority,
                      decoration: const InputDecoration(labelText: "Priority *", border: OutlineInputBorder()),
                      items: ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW'].map((p) =>
                          DropdownMenuItem(value: p, child: Text(p))).toList(),
                      onChanged: (val) => setState(() => selectedPriority = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Title & Description
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Issue Title *", hintText: "e.g. Oven not heating", border: OutlineInputBorder()),
                maxLength: 120,
                validator: (val) => val!.isEmpty ? "Enter a title" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),

              // 5. Media Picker Placeholder
              const Text("Upload Photos (Max 5)", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // 6. Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A56E2), foregroundColor: Colors.white),
                  onPressed: _submitTicket,
                  child: const Text("SUBMIT TICKET", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitTicket() {
    if (_formKey.currentState!.validate()) {
      // 1. Create ticket in Supabase (ticket_no is auto-generated by DB trigger) [cite: 215]
      // 2. Upload images to Supabase Storage [cite: 166, 606]
      // 3. Navigate back to Home
    }
  }
}