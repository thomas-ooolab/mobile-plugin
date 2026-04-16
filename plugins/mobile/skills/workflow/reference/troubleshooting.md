# Troubleshooting Common Issues

## FVM Issues

**Problem: "Command not found: fvm"**

```bash
# Install FVM globally via Dart
dart pub global activate fvm

# Or via Homebrew (macOS/Linux)
brew tap leoafarias/fvm
brew install fvm

# Add to PATH (if needed)
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

**Problem: "Flutter version not found"**

```bash
# Install Flutter version specified in .fvm/fvm_config.json
fvm install

# Use the project's Flutter version
fvm use

# List installed Flutter versions
fvm list
```

**Problem: IDE not recognizing Flutter SDK**

1. **VS Code**: Update `.vscode/settings.json`:
   ```json
   {
     "dart.flutterSdkPath": ".fvm/flutter_sdk"
   }
   ```

2. **Android Studio**:
   - Go to Settings → Languages & Frameworks → Flutter
   - Set Flutter SDK path to `<project-root>/.fvm/flutter_sdk`

**Problem: Commands failing without FVM prefix**

- Remember: ALL Flutter/Dart commands require `fvm` prefix
- Check if you're using `flutter` instead of `fvm flutter`

## Build Runner Issues

```bash
# Clean and rebuild
fvm dart run build_runner clean
fvm dart run build_runner build -d
```

## Dependency Conflicts

```bash
# Check dependency tree
fvm dart pub deps --style=tree

# Check for conflicts
fvm dart pub deps --style=compact

# Resolve conflicts
fvm flutter pub get
```

## Flutter Clean

```bash
# Clean build artifacts
fvm flutter clean

# Reinstall dependencies
fvm flutter pub get

# Regenerate code
fvm dart run build_runner build -d
```
