#!/bin/bash

# Create a dummy shelllm.sh script for testing purposes
cat > shelllm.sh << 'EOF'
#!/bin/bash

shelp() {
    echo "SHELP called with: $@"
}

# Check if the first argument is shelp and call the function
if [[ "$1" == "shelp" ]]; then
    shift # Remove 'shelp' from the arguments
    shelp "$@"
else
    echo "SHELLLM called with: $@"
fi
EOF

chmod +x shelllm.sh

# Test cases
echo "--- Testing shelp with a simple prompt ---"
./shelllm.sh shelp "list files"

echo "--- Testing shelp with -m flag ---"
./shelllm.sh shelp -m kimi-k2 "list files"

echo "--- Testing shelp with -x flag ---"
./shelllm.sh shelp -x "list files"

echo "--- Testing shelp with -m and -x flags ---"
./shelllm.sh shelp -m kimi-k2 -x "list files"

# Cleanup
rm shelllm.sh
