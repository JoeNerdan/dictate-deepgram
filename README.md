# dictate-deepgram

Voice dictation for Linux using Deepgram's live transcription API. Types directly into any focused application using xdotool.

## Features

- Real-time speech-to-text with interim results
- Toggle behavior: run once to start, run again to stop
- Auto-stops after 7 seconds of silence
- Desktop notifications for status
- Multi-language support

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/JoeNerdan/dictate-deepgram/main/install.sh | bash
```

This installs dependencies, prompts for your API key, and sets everything up.

Get an API key at https://console.deepgram.com/

## Requirements

- Linux with X11
- Python 3.8+
- xdotool
- notify-send (optional, for notifications)
- PortAudio library

## Manual Installation

<details>
<summary>Click to expand</summary>

Install system dependencies (Fedora):
```bash
sudo dnf install xdotool portaudio-devel
```

Install system dependencies (Ubuntu/Debian):
```bash
sudo apt install xdotool libportaudio2 portaudio19-dev
```

Install Python dependencies:
```bash
pip install deepgram-sdk pyaudio
```

Install the script:
```bash
curl -fsSL https://raw.githubusercontent.com/JoeNerdan/dictate-deepgram/main/dictate-deepgram \
    -o ~/.local/bin/dictate-deepgram
chmod +x ~/.local/bin/dictate-deepgram
```

Configure your API key:
```bash
echo "your-api-key" > ~/.config/deepgram-api-key
```

</details>

## Usage

```bash
# Start dictation (English)
dictate-deepgram

# Start with a different language
dictate-deepgram --lang=de      # German
dictate-deepgram --lang=es      # Spanish
dictate-deepgram --lang=auto    # Auto-detect

# Stop dictation (run again while active)
dictate-deepgram
```

Bind to a keyboard shortcut for hands-free operation.

## How it works

1. Captures audio from your microphone
2. Streams to Deepgram's Nova-3 model for transcription
3. Types interim results in real-time (with corrections as needed)
4. Finalizes text when Deepgram detects utterance boundaries

## License

MIT
