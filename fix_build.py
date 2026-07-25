import re

with open('lib/screens/ticket_detail_screen.dart', 'r') as f:
    content = f.read()

old_build = """  @override
  Widget build(BuildContext context) {
    final bool isMobileDevice = MediaQuery.of(context).size.width < 768;
    if (!isMobileDevice) {
      return _buildWebTabletLayout(context);
    }
    return _buildMobileLayout(context);
  }"""

new_build = """  @override
  Widget build(BuildContext context) {
    final bool isMobileDevice = MediaQuery.of(context).size.width < 768;
    if (!isMobileDevice) {
      return DefaultTabController(
        length: 4,
        child: _buildWebTabletLayout(context),
      );
    }
    return _buildMobileLayout(context);
  }"""

content = content.replace(old_build, new_build)

with open('lib/screens/ticket_detail_screen.dart', 'w') as f:
    f.write(content)
