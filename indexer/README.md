# Indexer

This directory contains the configuration and code for indexing indentity rules from the blockchain using The Graph.

## Setup

1. Install the dependencies:

```bash
yarn
```

2. Install the Graph CLI:

```bash
npm install -g @graphprotocol/graph-cli
```

3. Authenticate with the Graph CLI:

```bash
graph auth --studio <ACCESS_TOKEN>
```

4. Create a new subgraph:

```bash
yarn codegen
yarn build
graph deploy --studio <SUBGRAPH_NAME>
```

## Endpoints

### Holesky Subgraph
```URL
https://gateway-testnet-arbitrum.network.thegraph.com/api/{api-key}/subgraphs/id/GfAum4BRNL7ZvBUs4HuRrDjwDN4KqnZGzCVb4jH5vfi7
```