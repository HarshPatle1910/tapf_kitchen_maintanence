import re

with open('lib/screens/ticket_detail_screen.dart', 'r') as f:
    content = f.read()

# We need to find the `Builder(builder: (context) { ... })` inside the body of Scaffold.
builder_pattern = re.compile(r'(child:\s*Builder\(\s*builder:\s*\(context\)\s*\{)(.*?)(^\s*\},?\n\s*\),?\n\s*\),?\n\s*\),?\n\s*bottomNavigationBar:)', re.DOTALL | re.MULTILINE)
match = builder_pattern.search(content)

if not match:
    print("Could not find the Builder block.")
    exit(1)

prefix = match.group(1)
builder_body = match.group(2)
suffix = match.group(3)

# Inside builder_body, we have:
# final bool isWeb = ...
# final Widget basicDetails = Column( ... );
# final Widget workDetails = Column( ... );
# final Widget adminActions = Column( ... );
# return isWeb ? Row(...) : Column(...);

# Let's extract the widgets.
# basicDetails contains everything from `if (isEditing) ...[` down to `TicketFormFields.buildDropdown(label: "Category *" ...)`
# I'll extract these chunks by searching for specific recognizable widget instantiations.

# But instead of parsing it blindly, I can just replace `builder_body` with the new Layout builder and I can use Python to grab the exact chunks I need.

print("Found Builder block.")
