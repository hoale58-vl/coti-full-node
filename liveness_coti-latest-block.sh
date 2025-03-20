#!/bin/bash

# Number of nodes
NODES=10
BASE_HTTP_PORT=8545

# Function to get the current block number
get_block_number() {
    local rpc_url="$1"

    curl -s -X POST "$rpc_url" \
        -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' | \
        jq -r '.result' | xargs printf "%d\n"
}

# Monitor block progression
for i in $(seq 1 $NODES); do
    port=$((BASE_HTTP_PORT - 1 + i))
    rpc="http://localhost:$port"

    # Initial block number
    block=$(get_block_number "$rpc")
    echo "🪖 block number: $block"
done

exit 0

