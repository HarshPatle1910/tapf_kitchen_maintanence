// ignore_for_file: avoid_print
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://sfjjxmdkdswothebcbbd.supabase.co/rest/v1/ticket_media?select=*&limit=1');
  final response = await http.get(url, headers: {
    'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNmamp4bWRrZHN3b3RoZWJjYmJkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY0ODg2NjIsImV4cCI6MjA5MjA2NDY2Mn0.oFdI4Azq71VjJ7q0BHacOfv88QTKt0tCLVecmngkjrU',
    'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNmamp4bWRrZHN3b3RoZWJjYmJkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY0ODg2NjIsImV4cCI6MjA5MjA2NDY2Mn0.oFdI4Azq71VjJ7q0BHacOfv88QTKt0tCLVecmngkjrU'
  });
  print(response.body);
}
