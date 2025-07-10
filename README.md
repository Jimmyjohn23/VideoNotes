# 🎥 Video Notes Generator with Whisper.cpp + Ollama

This script (`video_notes.sh`) takes a video file, extracts its audio, transcribes it using [whisper.cpp](https://github.com/ggerganov/whisper.cpp), and generates a concise summary using [Ollama](https://ollama.com/) and an LLM (e.g., `phi3`).

---

## ✨ Features

- ✅ Auto-installs `ffmpeg`, `whisper.cpp`, and `ollama` (if missing)
- 🎧 Extracts audio from any video file to `.wav`
- 🧠 Transcribes locally using `whisper.cpp`
- 📝 Summarizes with Ollama into structured Markdown
- ⚡ Works fully offline after initial setup

---

## 🛠 Requirements

- Unix-like system (Linux/macOS)
- Git, `ffmpeg`, `cmake`, `make`
- Ollama (installed or installable via `brew`)
- Internet for first run (model downloads)

---

## 🚀 Usage

### 1. Clone & Run

```bash
git clone https://github.com/jimmyjohn23/video-notes.git
cd video-notes
chmod +x video_notes.sh
./video_notes.sh your_video.mp4
