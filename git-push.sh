#!/bin/bash
# Script to push with token authentication
# Usage: ./git-push.sh YOUR_GITHUB_TOKEN

if [ -z "$1" ]; then
    echo "Usage: $0 YOUR_GITHUB_TOKEN"
    echo "Get a token at: https://github.com/settings/tokens"
    exit 1
fi

TOKEN="$1"
REPO="https://${TOKEN}@github.com/marcorobol/isarco-llama.git"

singularity exec ~/localai/llamacpp-cuda-complete.sif git push -u origin master
