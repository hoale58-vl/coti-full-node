#!/bin/bash

NODES=10
BASE_HTTP_PORT=8545
BASE_WS_PORT=8446
BASE_P2P_PORT=7400

FULLNODE_EXT_IP=$( curl -s https://api.ipify.org )
echo "ℹ️ FULLNODE_EXT_IP="$FULLNODE_EXT_IP

# Init docker-compose.yml
cat <<EOF > docker-compose.yml
services:
  coti-full-node-genesis:
    image: coti/full-node:1.1.3
    container_name: coti-full-node-genesis
    command: --datadir=/execution init /coti-genesis/genesis.json
    volumes:
      - ./execution/:/execution
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "1"
EOF

# Loop
for i in $(seq 1 $NODES); do
  NODE_HTTP_PORT=$((BASE_HTTP_PORT - 1 + i))
  NODE_WS_PORT=$((BASE_WS_PORT - 1 + i))
  NODE_P2P_PORT=$((BASE_P2P_PORT - 1 + i))

  cat <<EOF >> docker-compose.yml

  coti-full-node-$i:
    image: coti/full-node:1.1.3
    container_name: coti-full-node-$i
    command:
      - --soda.engine
      - --soda.seqaddr=0x7d9938777950631645B5B16057A2c52391a8e787
      - --soda.exec1addr=0x787A4bB8677189682AD2AFf2becB78A2ED9d1241
      - --soda.exec2addr=0x183B8933c370A2736c9766379349D72154Bd0b8f
      - --soda.validator
      - --networkid=7082400
      - --http
      - --http.api=eth,net,web3,txpool
      - --http.corsdomain=*
      - --http.vhosts=*
      - --http.addr=0.0.0.0
      - --http.port=$NODE_HTTP_PORT
      - --port=$NODE_P2P_PORT
      - --identity=cotiagents-node-$i
      - --verbosity=3
      - --datadir=/execution/node$i
      - --syncmode=full
      - --ws
      - --ws.port=$NODE_WS_PORT
      - --ws.addr=0.0.0.0
      - --ws.origins=*
      - --ws.api=web3,eth
      - --metrics
      - --metrics.expensive
      - --metrics.addr=0.0.0.0
      - --rpc.allow-unprotected-txs=true
      - --miner.gasprice=5000000
      - --bootnodes=enode://8c14ae1db71cc9796bf04cf3cc5508291621bc8b9c4c80d4d7b79d8e4b33eadcfc2298242362443fd1317c5ac887dae8e8fe9c551d7792f2bc2e7177978f730a@147.135.77.48:7400
      - --nat=extip:$FULLNODE_EXT_IP
    ports:
      - "${NODE_HTTP_PORT}:${NODE_HTTP_PORT}"
      - "${NODE_WS_PORT}:${NODE_WS_PORT}"
      - "${NODE_P2P_PORT}:${NODE_P2P_PORT}"
    depends_on:
      coti-full-node-genesis:
        condition: service_completed_successfully
    volumes:
      - ./execution/node-$i:/execution/
      - ./execution/keystore-$i:/execution/keystore
    logging:
      driver: "json-file"
      options:
        max-size: "50m"
        max-file: "5"
EOF
done

echo "✅ docker-compose.yml created!"

docker-compose up -d