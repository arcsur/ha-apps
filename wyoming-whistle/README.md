# Home Assistant App: Wyoming Whistle

_Ultra-lightweight local Speech-to-Text using Cactus Compute's Whistle model via the Wyoming protocol._

![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg

## About

**Whistle** is an open-weights, ultra-lightweight (16.9 MB) speech-to-text model developed by [Cactus Compute](https://cactuscompute.com). It is engineered for fast, edge and CPU-friendly offline transcription.

This Home Assistant app exposes Whistle as a local speech-to-text service using Home Assistant's native [Wyoming protocol](https://github.com/rhasspy/wyoming).

### Highlights

- **16.9 MB Model Footprint:** Minimal memory and CPU consumption compared to larger Whisper models.
- **Languages Supported:** English (`en`), German (`de`), French (`fr`), Spanish (`es`), Italian (`it`), Dutch (`nl`), Polish (`pl`), with automatic language detection.
- **Zero-Cloud & 100% Local:** Entirely self-contained with no external API calls.
- **Automatic Supervisor Discovery:** Instantly discovers itself in Home Assistant as a Wyoming STT provider.

## Installation

1. Add this repository to your Home Assistant App Store: `https://github.com/arcsur/ha-apps`
2. Install **Wyoming Whistle**.
3. Start the app.
4. Navigate to **Settings > Devices & Services** and configure the discovered Wyoming service.
5. In **Settings > Voice Assistants**, set the Speech-to-text engine to **Whistle**.
