# EIP-88 Constitution

This repository contains the smart contracts and tests for an EIP-88 compliant contract. The system includes a Constitution contract for managing an interacting system of humans and non-human AIs and a SystemConfig contract for managing configurations.

## Getting Started

### Prerequisites

* Solidity
* Foundry: A toolkit for Ethereum application development.

### Installation

```shell
mkdir foundry
cd foundry

brew install solidity
curl -L https://foundry.paradigm.xyz | bash

source ~/.bashrc 
# OR if you use mac / zsh
source /Users/yourName/.zshenv 
# OR start a new terminal session
foundryup
```

### Building Contracts

To build the contracts, run:

```shell
forge build
```

### Running Tests

To run the tests:

```shell
forge test
```