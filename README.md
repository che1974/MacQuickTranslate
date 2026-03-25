# MacQuickTranslate

Native macOS menu bar app for instant translation across 37 European languages. Runs entirely on-device using Apple MLX — no servers, no API keys, no internet required after the initial model download.

Select text anywhere, press **⌘⇧T**, get the translation in a floating popup near your cursor.

## How it works

1. You press **⌘⇧T** with text selected in any app
2. The app simulates **⌘C** via CGEvent to capture the selection, then restores your clipboard
3. Source language is auto-detected by Unicode analysis (Cyrillic, Greek, Latin scripts)
4. A prompt is built for the selected translation model with source/target language codes
5. The model runs inference locally through [MLX](https://github.com/ml-explore/mlx) on the Metal GPU
6. Tokens stream into a floating NSPanel popup near the cursor in real-time
7. After 5 minutes of inactivity the model is unloaded from memory (~2-3 GB freed)
8. Next translation request loads the model again from local cache in ~2-3 seconds

The app sits in the menu bar with no Dock icon (`LSUIElement`). The popup uses `NSPanel` with `.nonactivatingPanel` style so it never steals focus from the app you're working in.

## Why Metal GPU and not Neural Engine (NPU)

Apple Silicon chips have three compute units for ML: CPU, GPU (Metal), and Neural Engine (ANE/NPU). Each has trade-offs for LLM inference:

| | Metal GPU | Neural Engine (NPU) |
|---|---|---|
| **Framework** | MLX | Core ML |
| **Model format** | MLX (HuggingFace) | .mlmodelc |
| **Max model size** | Limited by unified memory (up to 32-192 GB) | ~4 GB practical limit |
| **LLM support** | Full (any transformer architecture) | Limited (encoder-decoder models hard to convert) |
| **Streaming** | Native token-by-token | Not designed for autoregressive generation |
| **Quantization** | 4-bit, 8-bit via MLX | 16-bit, some 8-bit via Core ML |
| **Throughput** | 20-40 tokens/sec (M1) | Higher for small fixed-size models |
| **Flexibility** | Load any HuggingFace model | Requires conversion per model |

Translation models like TranslateGemma (4B parameters, ~2.2 GB quantized) exceed the practical NPU memory budget. Core ML conversion of encoder-decoder architectures (like Opus-MT) fails on unsupported operations (`new_ones`, dynamic shapes). The autoregressive token generation loop that LLMs require is not what the Neural Engine was optimized for — it excels at single-pass inference (image classification, speech recognition).

MLX on Metal GPU gives us the full HuggingFace ecosystem, simple model switching, streaming generation, and no conversion step. The 20-40 tok/s on M1 translates to 2-4 seconds for a typical paragraph — fast enough for interactive use.

## Features

- **Fully local** — on-device inference via MLX (Metal GPU), no external services
- **37 European languages** — Slavic, Germanic, Romance, Baltic, Finno-Ugric, Celtic, Greek, Turkish and more
- **Global hotkey** — works from any application without switching focus
- **Auto language detection** — Cyrillic, Greek, Latin script analysis
- **Streaming output** — translation appears token by token in real-time
- **Multi-model support** — Gemma 2 2B (1.5 GB, light) or TranslateGemma 4B/12B (specialized)
- **Lazy loading** — model loads on first use, unloads after 5 min idle to free memory
- **Floating popup** — translucent panel with vibrancy, scrollable, positioned near cursor
- **Translation history** — last 10 translations accessible from menu bar
- **Model management** — view cache size, delete downloaded models from settings
- **Clipboard-safe** — restores your clipboard after capturing selected text

## Requirements

- macOS 14 (Sonoma) or later
- Apple Silicon (M1/M2/M3/M4)
- ~2-5 GB free disk space for model cache

## Build & Run

```bash
# Metal shaders require xcodebuild (not plain swift build)
xcodebuild -scheme MacQuickTranslate -destination 'platform=macOS' build

# Or open in Xcode
open Package.swift
```

On first translation the app downloads the selected model from HuggingFace (~2.2 GB for default) and requests Accessibility permission (System Settings → Privacy & Security → Accessibility).

## Usage

1. Select text in any application
2. Press **⌘⇧T**
3. Translation appears in a popup near your cursor
4. Click **Copy** or press **Esc** to dismiss

Click the menu bar icon to change target language, switch model, or view history.

## Available Models

| Model | Size | Speed | Use case |
|-------|------|-------|----------|
| Gemma 2 2B (4-bit) | ~1.5 GB | Fastest | Quick drafts, lightweight |
| TranslateGemma 4B (4-bit) | ~2.2 GB | Fast | Default, good quality |
| TranslateGemma 4B (8-bit) | ~4.4 GB | Fast | Better quality |
| TranslateGemma 12B (4-bit) | ~7 GB | Slower | Best quality |

Models are downloaded from [HuggingFace MLX Community](https://huggingface.co/mlx-community) and cached in `~/.cache/huggingface/`.

## Supported Languages

Slavic: Russian, Ukrainian, Polish, Czech, Slovak, Slovenian, Bulgarian, Macedonian, Serbian, Croatian, Bosnian
Germanic: English, German, Dutch, Swedish, Norwegian, Danish, Icelandic
Romance: French, Spanish, Italian, Portuguese, Romanian, Catalan, Galician
Baltic: Latvian, Lithuanian · Finno-Ugric: Finnish, Estonian, Hungarian
Celtic: Irish, Welsh · Other: Greek, Turkish, Albanian, Maltese, Basque

## Adding translation models

1. Add a `TranslationModelConfig` static entry in `TranslationModel.swift` with the HuggingFace model ID
2. Add it to the `allModels` array
3. Choose prompt strategy: `.translateGemma` (structured messages) or `.textPrompt` (general LLM)

## Performance

| Metric | Value |
|--------|-------|
| App startup (no model) | < 1s, ~20 MB memory |
| Model load (from cache) | 2-3s |
| Time to first token | < 1s after model loaded |
| Translation speed | 20-40 tokens/sec (M1) |
| Typical paragraph (50 words) | 2-4s |
| Auto-unload | After 5 min idle |

## Architecture

```
QuickTranslateApp (MenuBarExtra)
  └─ AppState (orchestrator)
       ├─ HotkeyManager (⌘⇧T via Carbon/HotKey)
       ├─ ClipboardManager (CGEvent ⌘C simulation)
       ├─ TranslationService (MLX model loading + streaming inference)
       │    └─ TranslationModelConfig (prompt strategy per model)
       └─ PopupWindowManager (NSPanel + NSVisualEffectView)
```
