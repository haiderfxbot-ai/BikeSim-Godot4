# Realistic Bike Simulator

A professional-grade 2D realistic motorcycle mechanics simulator built with **Godot 4** for Android.

## Overview

Experience the most authentic motorcycle simulation on mobile. This AI-engineered project, developed under **HAIDER** branding, simulates every aspect of real bike mechanics:

- **Realistic Engine Physics** — RPM, clutch engagement, gear ratios, stall mechanics, kick-start sequences
- **Full Clutch Control** — Press and release the clutch with realistic power transfer to the rear wheel
- **Multi-Gear Gearbox** — 4-speed sequential transmission with neutral (0)
- **Advanced Crash System** — Gear-shock penalties, wheelie/stoppie flips, ghost ride runaway, and out-of-control physics
- **Mobile Touch UI** — Custom on-screen controls for key, kick, clutch, throttle, brakes, and gear shifting
- **Dynamic Sound Management** — Engine rev matching, crash sounds, kick-start audio

## Controls

| Control | Action |
|---------|--------|
| Key Switch | Toggle ignition ON/OFF |
| Kick Start | Start engine (Neutral required unless clutch pulled) |
| Clutch | Hold to disengage power, release to engage |
| Throttle | Twist to accelerate (0% – 100%) |
| Gear Up / Down | Shift through 1–4 gears |
| Brake | Apply wheel brakes |

## Build from Source

### Prerequisites
- Godot 4.3+ (mono or standard)
- Android SDK (API 33)
- Android NDK 25.2

### Export
Open the project in Godot, go to **Project → Export**, select the Android preset, and click **Export Project**.

### CI/CD
Push to the `main` branch — GitHub Actions automatically builds a release APK and uploads it as a workflow artifact.

## Tech Stack

- **Engine:** Godot 4.3 (GL Compatibility renderer)
- **Language:** GDScript (fully typed)
- **Target:** Android (API 23+, arm64-v8a / armeabi-v7a)
- **Architecture:** Autoload singletons for Sound & Game Rules, scene-based composition

---

**HAIDER** — Precision Engineering, Digital Craftsmanship.
