#!/bin/bash
# Simple chat client for GLM-4 API

BASE_URL="${1:-http://localhost:8080}"
MODEL="glm-4-9b-chat"

echo "GLM-4 Chat Client"
echo "Connected to: $BASE_URL"
echo "Type 'quit' to exit"
echo ""

# Chat history
MESSAGES='[]'

while true; do
    echo -n "You: "
    read PROMPT
    
    if [ "$PROMPT" = "quit" ]; then
        echo "Goodbye!"
        exit 0
    fi
    
    # Add user message to history
    MESSAGES="$(echo $MESSIONS | jq --arg msg "$PROMPT" '. + [{role: "user", content: $msg}]')"
    
    # Call API
    RESPONSE=$(curl -s "$BASE_URL/v1/chat/completions" \
        -H 'Content-Type: application/json' \
        -d "$(echo $MESSIONS | jq -n --argjson msgs \"\$MESSAGES\" --arg model \"\$MODEL\" \
            '{model: $model, messages: $msgs, stream: false}')" )
    
    # Extract assistant message
    ASSISTANT_MSG=$(echo $RESPONSE | jq -r '.choices[0].message.content')
    
    echo -e "\nAssistant: $ASSISTANT_MSG\n"
    
    # Add assistant response to history
    MESSAGES="$(echo $MESSAGES | jq --arg msg "$ASSISTANT_MSG" '. + [{role: "assistant", content: $msg}]')"
done
