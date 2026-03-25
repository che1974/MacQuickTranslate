# Changelog

## v1.1.0

### New Features
- **Translation styles** — choose between Standard, Casual, Formal, Technical, and Creative translation tones (available with Gemma 2B model)
- **Replace text** — "Replace" button in the popup pastes the translation directly into the source app via simulated Cmd+V
- **37 European languages** — expanded from RU/EN to full European coverage: Slavic, Germanic, Romance, Baltic, Finno-Ugric, Celtic, Greek, Turkish, Albanian, Maltese, Basque
- **Gemma 2 2B model** — lighter alternative (~1.5 GB) alongside TranslateGemma 4B/12B
- **Lazy model loading** — model loads on first translation, not at app startup
- **Auto-unload** — model unloads after 5 minutes of inactivity to free ~2-3 GB memory
- **Model cache management** — view download size and delete cached models from settings
- **Scrollable popup** — long translations no longer get cut off

### Improvements
- Target language picker in menu bar settings
- Auto-detect source with manual override option
- Better stop token handling (no more duplicated output)
- Increased popup max height to 500pt

## v1.0.0

Initial release.

- On-device RU↔EN translation via MLX (Metal GPU)
- TranslateGemma 4B model with streaming output
- Global hotkey (Cmd+Shift+T)
- Floating popup near cursor with vibrancy
- Auto language detection (Cyrillic/Latin)
- Translation history (last 10)
- Menu bar interface with connection status
