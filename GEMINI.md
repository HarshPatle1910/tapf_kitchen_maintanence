## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).

## Core Documentation Maintenance

Always maintain the project's living documentation files:
- **`flow.md`**: Update when application workflows, navigation paths, state machines, API integration pipelines, or lifecycle steps change.
- **`decisions.md`**: Add or update Architecture Decision Records (ADRs) whenever architectural, structural, or technology choices are made or modified.
- **`changes.md`**: Maintain a clean changelog following the Keep a Changelog standard with version numbers, dates, and categorized entries (`Added`, `Changed`, `Fixed`, etc.).

