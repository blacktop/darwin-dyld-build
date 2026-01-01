# NOTES

## PATCHING

The patches make the following modifications to support building with the public SDK:

| Area | Changes |
|------|---------|
| **Internal Headers** | Wrapped with `__has_include` guards, stub implementations provided |
| **kdebug tracing** | Stubbed - tracing calls become no-ops |
| **Sandbox APIs** | Stubbed - sandbox checks return success |
| **ObjC Introspection** | Stubbed - ObjC class/method inspection returns empty results |
| **Swift Metadata** | Stubbed - Swift protocol conformance lookup disabled |
| **Availability Macros** | Fixed `bridgeos` platform recognition |

### Preserved Functionality

- Mach-O parsing and analysis
- Segment/section enumeration
- Fixup chain analysis
- Export/import symbol listing
- Shared cache mapping and extraction
- Cache statistics and info

### Disabled Functionality

Features requiring internal SDK (gracefully stubbed):
- ObjC class introspection (`-objc-classes`, `-objc-info`)
- Swift protocol conformances (`-swift-proto`)
- Symbol disassembly
- VA symbol lookup with disassembly
