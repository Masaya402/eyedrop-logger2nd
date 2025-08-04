# EyeDropLogger

Simple SwiftUI iOS app to log eyedrop usage.

## Features
* Record the time you administer your eyedrops with a single tap.
* Supports up to **three different eyedrop types**.
* Keeps a rolling log of the last **180 days**.
* All data stored securely on-device (using `UserDefaults`).

## Project Structure
```
EyeDropLoggerApp.swift   – App entry-point
ContentView.swift        – Main UI (picker + log list)
Models.swift             – Data models (EyeDropType, EyeDropEntry)
DataStore.swift          – Persistence layer (load/save/prune)
```

## Getting Started
1. In Xcode ➝ **File ▸ Open…** and choose this folder (`EyeDropLogger`).  
   Xcode will recognise the Swift files and create an iOS App project for you.
2. Select a simulator or a connected iPhone and **Run ▶︎**.

That’s it – press the *Drop!* button to add a timestamp.
