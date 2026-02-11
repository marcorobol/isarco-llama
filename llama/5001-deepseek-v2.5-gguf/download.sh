#!/bin/bash
# Download script for DeepSeek V2.5 GGUF Q6_K model
# Total size: ~193GB (5 split files)

set -e

MODEL_DIR="/data/models/DeepSeek-V2.5-GGUF/Q6_K"
HF_BASE="https://huggingface.co/lmstudio-community/DeepSeek-V2.5-GGUF/resolve/main"

# Q6_K files (5 parts, ~193GB total)
FILES=(
    "DeepSeek-V2.5-Q6_K-00001-of-00005.gguf"
    "DeepSeek-V2.5-Q6_K-00002-of-00005.gguf"
    "DeepSeek-V2.5-Q6_K-00003-of-00005.gguf"
    "DeepSeek-V2.5-Q6_K-00004-of-00005.gguf"
    "DeepSeek-V2.5-Q6_K-00005-of-00005.gguf"
)

echo "Creating model directory: $MODEL_DIR"
mkdir -p "$MODEL_DIR"

echo ""
echo "Downloading DeepSeek V2.5 GGUF Q6_K model..."
echo "Total size: ~193GB (5 files)"
echo ""

for FILE in "${FILES[@]}"; do
    echo "Downloading $FILE..."
    if [ -f "$MODEL_DIR/$FILE" ]; then
        echo "  Already exists, skipping"
    else
        wget -c "$HF_BASE/$FILE" -O "$MODEL_DIR/$FILE"
        echo "  Done"
    fi
    echo ""
done

echo "All files downloaded successfully!"
echo ""
echo "Model files location: $MODEL_DIR"
ls -lh "$MODEL_DIR"
