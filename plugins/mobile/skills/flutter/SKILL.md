---
name: flutter
description: "Flutter widget architecture, composition rules, and performance patterns. Use when writing or reviewing Flutter widgets, screens, or UI components in this project."
---

## Related Guidelines

This document focuses on Flutter-specific patterns. For complete guidance, also refer to:
- `@dart` - Dart language best practices, patterns, naming conventions
- `@state` - BLoC/Cubit patterns, state management, testing
- `@clean` - Layer separation, dependency injection, repositories
- `@test` - Testing strategies and patterns

## Key Principles

### Flutter-Specific Best Practices
1. **Use Widget Classes** - ALWAYS extract widgets into classes, NOT build methods
2. **Const Constructors** - Use const everywhere possible for performance
3. **Widget Composition** - Build widget trees with classes, not nested functions
4. **StatelessWidget First** - Prefer StatelessWidget, use StatefulWidget only for local UI state
5. **Small, Focused Widgets** - Keep widgets under 200 lines, extract complexity

## Reference Documentation

| Topic | File | What's inside |
|-------|------|---------------|
| Widget Classes vs Build Methods, StatelessWidget vs StatefulWidget, Composition, Keys | [`reference/widget-architecture.md`](reference/widget-architecture.md) | Full rules with DO/DON'T examples |
| Const constructors, List performance, Image optimization, Build optimization | [`reference/performance.md`](reference/performance.md) | Performance patterns with code examples |
| Component design, Package structure, Theming, Naming conventions | [`reference/ui-kit.md`](reference/ui-kit.md) | UI kit package guidelines |

## Best Practices Summary

### DO
- Use Widget classes instead of build methods for ALL reusable components
- Use const constructors wherever possible
- Use StatelessWidget by default
- Use StatefulWidget ONLY for local UI state (animations, controllers)
- Use BLoC/Cubit for business logic (see `@state`)
- Use ListView.builder for long lists
- Use CachedNetworkImage for network images
- Use keys for list items
- Split large widgets into smaller, focused widget classes
- Keep widgets under 200 lines
- Organize widgets by feature
- Use UI kit components for consistent design

### DON'T
- Use build methods (_buildXxx) for reusable widgets with parameters
- Use StatefulWidget for business logic
- Create widgets in variables within build method
- Create deeply nested widget trees (>5 levels) without extraction
- Use ListView() constructor for long lists
- Skip keys in list items
- Ignore const optimization opportunities
- Hardcode strings (use localization)

### PREFER
- Widget classes over build methods (always!)
- Composition over complex widgets
- Small, focused widgets over large monolithic widgets
- Named parameters for all widget constructors
- Extracting to widget class if >5 lines or has parameters
- UI kit components over custom implementations

### AVOID
- Build methods with parameters
- Widgets larger than 200 lines
- Deep nesting without extraction
- Mixing business logic and UI
- Direct repository/service calls from widgets
- Ignoring performance best practices

## References

- [Flutter Official Documentation](https://flutter.dev/docs)
- [Flutter Performance Best Practices](https://flutter.dev/docs/perf/best-practices)
- [Material Design 3](https://m3.material.io/)
- See also: `@dart`, `@state`, `@clean`, `@test`
