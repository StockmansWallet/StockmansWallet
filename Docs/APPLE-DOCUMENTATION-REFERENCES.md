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
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Performance Best Practices](https://developer.apple.com/documentation/xcode/improving-your-app-s-performance)

---

## Add Your URLs Below

Please add any specific documentation URLs you want referenced:

1. 
2. 
3. 
4. 
5. 

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

