# Apple Documentation References

This file contains important Apple documentation URLs for quick reference during development.

## SwiftData & Performance

### Core Documentation
- [SwiftData Overview](https://developer.apple.com/documentation/swiftdata/)
- [FetchDescriptor](https://developer.apple.com/documentation/swiftdata/fetchdescriptor)
- [Query Macro](https://developer.apple.com/documentation/swiftdata/query)
- [ModelContext](https://developer.apple.com/documentation/swiftdata/modelcontext)
- [Predicate Macro](https://developer.apple.com/documentation/foundation/predicate)

### Performance Best Practices
- [SwiftData Performance](https://developer.apple.com/documentation/swiftdata/optimizing-performance)
- [Modeling Data](https://developer.apple.com/documentation/swiftdata/modeling-data)

## SwiftUI Performance

### List & ScrollView Performance
- [SwiftUI Performance](https://developer.apple.com/documentation/swiftui/framing-a-view-refresh)
- [LazyVStack](https://developer.apple.com/documentation/swiftui/lazyvstack)
- [List](https://developer.apple.com/documentation/swiftui/list)

### State Management
- [Observable Macro](https://developer.apple.com/documentation/observation/observable())
- [State](https://developer.apple.com/documentation/swiftui/state)
- [Query Property Wrapper](https://developer.apple.com/documentation/swiftdata/query)

## Concurrency & Tasks
- [Swift Concurrency](https://developer.apple.com/documentation/swift/swift_standard_library/concurrency)
- [Task](https://developer.apple.com/documentation/swift/task)
- [TaskGroup](https://developer.apple.com/documentation/swift/taskgroup)
- [MainActor](https://developer.apple.com/documentation/swift/mainactor)

## iOS Design Guidelines

### iOS 26 Specific
- [iOS 26 Overview](https://www.apple.com/os/ios/) - Official iOS 26 features and Liquid Glass design language
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/) - Complete HIG reference
- [iOS 26 Design Resources](https://developer.apple.com/design/resources/) - UI kits, templates, and assets
- [Liquid Glass Design Language](https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/materials/) - Materials and translucency

### Performance & Best Practices
- [Performance Best Practices](https://developer.apple.com/documentation/xcode/improving-your-app-s-performance)
- [Optimizing SwiftUI Performance](https://developer.apple.com/documentation/swiftui/optimizing-your-swiftui-app-s-performance)

---

## Project-Specific Design Documentation

Internal documentation about our design decisions and iOS 26 compliance:

1. [FLAT-DESIGN-VS-LIQUID-GLASS.md](./FLAT-DESIGN-VS-LIQUID-GLASS.md) - Why we use flat colors instead of Liquid Glass
2. [IOS26-BUTTON-AUDIT.md](./IOS26-BUTTON-AUDIT.md) - Complete button system HIG compliance
3. [HIG-COMPLIANCE-FIXES.md](./HIG-COMPLIANCE-FIXES.md) - Comprehensive HIG compliance audit

---

## Current Performance Issues

### Issue: Slow performance with individual animals (57 items)
- **Symptom**: App slow/unresponsive when viewing individual animals list
- **Started**: After adding 57 individual animals to mock data
- **Previous state**: Fast with only 15 herds
- **Current approach**: Need to identify bottleneck specific to individual animals display

### Attempted Fixes
1. ✅ Removed @Query live updates → manual fetching
2. ✅ Batch database queries (45+ → 1 query)
3. ✅ Instant UI display with background calculations
4. ✅ Lightweight cards with no async operations
5. ⚠️ Still slow - need deeper investigation

### Next Steps
- Profile the app to identify exact bottleneck
- Check if issue is in rendering, data fetching, or calculations
- Compare herds list performance vs individual animals list performance

