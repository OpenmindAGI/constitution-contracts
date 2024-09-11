# EIP-88 Constitution

This repository contains the smart contracts and tests for an EIP-88 compliant example contract. The system includes a Constitution contract for managing an interacting system of humans and non-human AIs and a SystemConfig contract for managing system configurations.

## Getting Started

### Prerequisites

* Foundry: A toolkit for Ethereum application development.

Installation

```shell
mkdir foundry
cd foundry
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc 
# OR if you use zsh
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