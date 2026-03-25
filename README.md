# QuickTranslate

Native macOS menu bar app for instant Russian ↔ English translation. All processing runs locally via [Ollama](https://ollama.com) — no internet required after setup.

Select text anywhere, press **⌘⇧T**, get the translation in a floating popup near your cursor.

## Features

- **Global hotkey** — works from any application without switching focus
- **Auto language detection** — Cyrillic text translates to English, Latin to Russian
- **Streaming output** — translation appears token by token in real-time
- **Multi-model support** — switch between TranslateGemma 4B and Opus-MT from the menu bar
- **Floating popup** — translucent panel with vibrancy, positioned near cursor
- **Translation history** — last 10 translations accessible from menu bar
- **Direction override** — force RU→EN or EN→RU regardless of auto-detection
- **Clipboard-safe** — restores your clipboard after capturing selected text

## Requirements

- macOS 13 (Ventura) or later
- Apple Silicon (M1/M2/M3) recommended
- [Ollama](https://ollama.com) installed and running

## Setup

```bash
# Install Ollama
brew install ollama

# Pull the default translation model (~3.3 GB)
ollama pull translategemma:4b

# Optional: Opus-MT models
ollama pull opus-mt-ru-en
ollama pull opus-mt-en-ru

# Start Ollama
ollama serve
```

## Build & Run

```bash
swift build
swift run
```

On first launch the app will request Accessibility permission (System Settings → Privacy & Security → Accessibility). This is required for the global hotkey and clipboard capture.

## Usage

1. Select text in any application
2. Press **⌘⇧T**
3. Translation appears in a popup near your cursor
4. Click **Copy** or press **Esc** to dismiss

Click the menu bar icon to change translation model, override direction, or view history.

## Adding translation models

The app supports any Ollama-compatible translation model. To add one:

1. Create a struct conforming to `TranslationModel` in `Sources/QuickTranslate/Models/`
2. Add it to the `availableModels` array in `TranslationService.swift`

## Performance

| Metric | Value |
|--------|-------|
| Time to first token | < 1s |
| Translation speed | 20–40 tokens/sec (M1) |
| Typical paragraph (50 words) | 2–4s |
| App memory | < 50 MB |

Ollama + model use ~4–5 GB of unified memory when loaded.
