#!/bin/bash
# Script to push with token authentication
# Usage: ./git-push.sh YOUR_GITHUB_TOKEN

if [ -z "$1" ]; then
    echo "Usage: $0 YOUR_GITHUB_TOKEN"
    echo "Get a token at: https://github.com/settings/tokens"
    exit 1
fi

TOKEN="$1"

# git is only available inside the Singularity container
# Use token for authentication
singularity exec git.sif bash -c "git remote set-url origin https://${TOKEN}@github.com/marcorobol/isarco-llama.git && git push -u origin master && git remote set-url origin https://github.com/marcorobol/isarco-llama.git"
