# chip-8-tvOS

tvOS frontend for the CHIP-8 emulator.

## Build

```bash
xcodebuild clean build -project Chip8tvOS.xcodeproj -scheme Chip8tvOS \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO ONLY_ACTIVE_ARCH=NO
```

## Architecture

Xcode project consuming `Chip8EmulatorPackage` via SPM. The dependency version is pinned in `Chip8tvOS.xcodeproj/project.pbxproj`.

- **Chip8ViewController** — main view controller, implements `Chip8EngineDelegate`
- **Chip8View** — UIView subclass for rendering pixels
- **TVInputCode / TVInputMappingService** — maps Siri Remote input to `Chip8InputCode`
- **RomPickerViewController / RomCell** — ROM selection UI

## Dependency Updates

When `Chip8EmulatorPackage` is tagged with a new version:
1. Update the version in `Chip8tvOS.xcodeproj/project.pbxproj`
2. Delete `Chip8tvOS.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
3. Build to verify

## Workflow

- Branch protection on `main`: PR required, `build` CI check required, enforce admins
- CI: `.github/workflows/build.yml` — xcodebuild on macOS

### PR flow

1. Commit to a feature branch
2. Push and create PR
3. Set PR to auto-merge (`gh pr merge --auto --squash`)
4. CI must pass before merge completes
