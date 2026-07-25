import re

with open('lib/screens/ticket_detail_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("final _supabase = Supabase.instance.client;", "// final _supabase = Supabase.instance.client;")
content = content.replace("_supabase.storage", "// _supabase.storage")
content = content.replace("_supabase.from", "// _supabase.from")

with open('lib/screens/ticket_detail_screen.dart', 'w') as f:
    f.write(content)
