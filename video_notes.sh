#!/bin/bash

# This script processes video files and generates notes based on their content.
install_package() {
    PACKAGE="$1"
    if command -v apt-get &> /dev/null; then
        sudo apt-get install -y "$PACKAGE"
    elif command -v yum &> /dev/null; then
        sudo pacman -Sy --noconfirm "$PACKAGE"
    elif command -v brew &> /dev/null; then
        brew install "$PACKAGE"
    else
        echo "Package manager not found. Please install $PACKAGE manually."
        exit 1
    fi
}
if ! command -v ffmpeg &> /dev/null; then
    echo "ffmpeg is not installed. Installing..."
    install_package ffmpeg
fi

if ! command -v whisper &> /dev/null; then
    echo "whisper.cpp is not installed. Installing..."

    git clone https://github.com/ggerganov/whisper.cpp.git
    cd whisper.cpp
    mkdir -p build && cd build
    cmake ..
    make

    # Install 'main' binary as 'whisper'
    sudo cp bin/main /usr/local/bin/whisper
    cd ../..

    # Download the base English model if missing
    mkdir -p models
    MODEL_PATH="models/ggml-base.en.bin"
    if [ ! -f "$MODEL_PATH" ]; then
        echo "Downloading Whisper model..."
        wget -O "$MODEL_PATH" https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin
    fi
fi


if ! command -v ollama &> /dev/null; then
    echo "ollama is not installed. Installing..."
    if command -v brew &> /dev/null; then
        brew install ollama
    else
        echo "ollama is not available for your package manager. Please install it manually from https://ollama.com."
        exit 1
    fi
fi
# Check if the video file is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <video_file>"
    exit 1
fi

VIDEO="$1"
BASENAME=$(basename "$VIDEO" | cut -d. -f1)
AUDIO="${BASENAME}.wav"
TRANSCRIPT="${AUDIO}.txt"
SUMMARY="${BASENAME}_summary.md"

echo "Extracting audio from video..."
ffmpeg -i "$VIDEO" -vn -acodec pcm_s16le -ar 16000 -ac 1 "$AUDIO"

echo "Transcribing audio to text..."
./whisper.cpp/build/bin/whisper-cli --model models/ggml-base.en.bin --output-txt "$AUDIO"
echo "Transcript file generated: $TRANSCRIPT"
ls -l "$TRANSCRIPT"

if [ ! -f "$TRANSCRIPT" ]; then
    echo "Transcription failed. Please check the audio file and Whisper installation."
    exit 1
fi
echo "Generating summary using Ollama..."
MODEL="gemma:instruct"  # or mistral
PROMPT=$(cat <<EOF
You are a statistics teaching assistant. Your task is to summarize a lecture transcript into structured, clear markdown notes for a student.

Follow this format:

# 📘 Lecture Title: (Infer a short title)

## ✨ Summary
Write a 2–3 sentence overview of the lecture content.

## 📊 Key Concepts
- List and briefly explain the main statistical ideas (e.g., p-values, confidence intervals, central limit theorem).

## 🧮 Formulas Mentioned
- Format any mathematical expressions in Markdown (use LaTeX-style where needed, e.g., \$P(A \\cap B) = P(A)P(B)\$).

## 📈 Examples or Applications
- Summarize any use cases or real-world problems the lecture addressed.

## 📝 Definitions
- List terms and definitions introduced.

## ❓ Instructor’s Emphasis
- Note down any concepts the speaker emphasized, repeated, or highlighted as important for exams or practice.

## 🧠 Reflection / Takeaways
- One or two thoughtful takeaways a student should remember.

Transcript:
$(cat "$TRANSCRIPT")
EOF
)

SUMMARY_TEXT=$(ollama run "$MODEL" "$PROMPT")



echo "$SUMMARY_TEXT" > "$SUMMARY"
echo "Summary generated and saved to $SUMMARY"