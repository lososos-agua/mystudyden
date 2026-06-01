# Xcode Setup

## Required Tooling

Install full Xcode from the Mac App Store or Apple Developer downloads.

Command Line Tools alone are not enough for this project because iPhone Simulator builds require the full iOS SDK and Xcode app bundle.

After installing Xcode, run:

```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
xcodebuild -version
```

Then open:

```text
MyStudyDen.xcodeproj
```

## Project Shape

The Xcode app target is `MyStudyDen`.

The app target depends on the local Swift package product:

```text
Package.swift -> MyStudyDenCore
```

That keeps the domain model and mock AI pipeline testable outside the UI app.

## First Run Checklist

1. Open `MyStudyDen.xcodeproj`.
2. Select the `MyStudyDen` scheme.
3. Select an iPhone or iPad simulator.
4. Run the app.
5. If signing warnings appear, set a development team in the target settings.

## Known Current Limitations

- The app uses mock data only.
- SwiftData persistence is not connected yet.
- The Add Source flow is represented by a temporary `Add Packet` toolbar button.
- App icon artwork is placeholder metadata only.
- SwiftPM tests use Swift's test support and may fail under Command Line Tools only; switch `xcode-select` to full Xcode before treating test failures as code failures.
