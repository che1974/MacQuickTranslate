# QuickTranslate

Native macOS menu bar app for instant Russian ↔ English translation. Runs entirely on-device using Apple MLX — no servers, no API keys, no internet required after the initial model download.

Select text anywhere, press **⌘⇧T**, get the translation in a floating popup near your cursor.

## Features

- **Fully local** — on-device inference via MLX (Metal GPU), no external services
- **Global hotkey** — works from any application without switching focus
- **Auto language detection** — Cyrillic text translates to English, Latin to Russian
- **Streaming output** — translation appears token by token in real-time
- **Multi-model support** — switch between TranslateGemma variants from the menu bar
- **Floating popup** — translucent panel with vibrancy, positioned near cursor
- **Translation history** — last 10 translations accessible from menu bar
- **Direction override** — force RU→EN or EN→RU regardless of auto-detection
- **Clipboard-safe** — restores your clipboard after capturing selected text
- **Auto-download** — models download from HuggingFace on first launch

## Requirements

- macOS 14 (Sonoma) or later
- Apple Silicon (M1/M2/M3/M4)

## Build & Run

```bash
swift build
swift run
```

On first launch the app downloads TranslateGemma 4B (~2.2 GB) and requests Accessibility permission (System Settings → Privacy & Security → Accessibility).

## Usage

1. Select text in any application
2. Press **⌘⇧T**
3. Translation appears in a popup near your cursor
4. Click **Copy** or press **Esc** to dismiss

Click the menu bar icon to change translation model, override direction, or view history.

## Available Models

| Model | Size | Quality |
|-------|------|---------|
| TranslateGemma 4B (4-bit) | ~2.2 GB | Good, fast |
| TranslateGemma 4B (8-bit) | ~4.4 GB | Better quality |

Models are downloaded from [HuggingFace MLX Community](https://huggingface.co/mlx-community) and cached locally.

## Adding translation models

1. Add a new `TranslationModelConfig` entry in `TranslationModel.swift`
2. Add it to the `allModels` array

## Performance

| Metric | Value |
|--------|-------|
| Time to first token | < 1s |
| Translation speed | 20–40 tokens/sec (M1) |
| Typical paragraph (50 words) | 2–4s |
| Model memory (4-bit) | ~3 GB unified memory |
