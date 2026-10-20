# Home Assistant App: Wyoming Whistle

Wyoming protocol implementation for [Whistle](https://cactuscompute.com), an ultra-lightweight (16.9 MB) offline Speech-to-Text model created by Cactus Compute.

## Features

- **Fast & Lightweight:** Only 16.9 MB model size, runs in real-time on low-power CPUs without requiring GPU acceleration.
- **Offline & Private:** Transcribes audio locally on your machine with zero internet traffic or cloud dependencies.
- **Multilingual:** Supports English, German, French, Spanish, Italian, Dutch, and Polish, with automatic language detection.
- **Home Assistant Voice Integration:** Seamless integration into Home Assistant's Year of Voice pipelines via the Wyoming protocol.

## Configuration

### Option: `language`

The spoken language to transcribe. Defaults to `auto` (detect language automatically).
Supported languages:
- `auto`: Automatic detection
- `en`: English
- `de`: German
- `fr`: French
- `es`: Spanish
- `it`: Italian
- `nl`: Dutch
- `pl`: Polish

### Option: `debug`

Set to `true` to enable verbose debug logging in the app logs.

## Setting Up in Home Assistant

1. Start the **Wyoming Whistle** app.
2. Home Assistant will automatically discover the Wyoming service under **Settings > Devices & Services**. Click **Configure** and follow the prompt.
   - Alternatively, add it manually under **Settings > Devices & Services > Add Integration > Wyoming Protocol** using host `localhost` (or the container name) and port `10300`.
3. Go to **Settings > Voice Assistants > Assist**.
4. Select your voice assistant pipeline (or create a new one).
5. Set **Speech-to-text** to **Whistle**.
