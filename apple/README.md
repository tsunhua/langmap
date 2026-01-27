# LangMap iOS App

Native iOS application for LangMap language map.

## Prerequisites

- Xcode 15+
- iOS 15.0+ deployment target
- macOS 13+ (Ventura)

## Setup

1. Open `apple/langmap.xcodeproj` in Xcode
2. Select your development team in signing settings
3. Build and run (Cmd+R)

## Architecture

- **MVVM Pattern**: Separates UI from business logic
- **SwiftUI**: Modern declarative UI framework
- **Core Data**: Offline caching
- **URLSession**: API networking

## Testing

Run tests: Cmd+U in Xcode or:

```bash
cd apple
xcodebuild test -scheme langmap -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Building for App Store

1. Select Release configuration
2. Update version and build numbers
3. Archive: Product > Archive
4. Upload to App Store Connect
