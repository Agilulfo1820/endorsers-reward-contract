# VeChain Hardhat Template

A complete development environment template for building smart contracts on VeChain using Hardhat. This template comes pre-configured with everything you need to start developing, testing, and deploying smart contracts on VeChain networks.

## Features

- ✅ Hardhat configuration for VeChain networks (Solo, Testnet, Mainnet)
- 🐳 Thor-Solo instance for local development
- 📦 Upgradeable smart contracts templates
- 🧪 Comprehensive test suite setup
- 🔧 Deploy and upgrade scripts
- 🎭 Mock contracts for common VeChain contracts

## Prerequisites

- Node.js v20 (version specified in `.nvmrc`)
- Yarn or npm
- Docker (for running Thor-Solo)

## Installation

1. Install dependencies:

```bash
yarn install
```

2.  Create your environment file:

```bash
cp .env.example .env
```

## Usage

### Local Development

1. Start the Thor-Solo instance:

```bash
yarn start-solo
```

### Compile

```bash
yarn compile
```

### Deploy

```bash
yarn deploy:solo
```

or

```bash
yarn deploy:testnet
```

or

```bash
yarn deploy:mainnet
```

### Test

```bash
yarn test
```

or to generate a coverage report:

```bash
yarn test:coverage:solidity
```

Will generate the coverage report in the `coverage` folder, open the `index.html` file in your browser to see the report.

### Generate Docs

```bash
yarn generate-docs
```

Will generate the docs in the `docs` folder.

## Warning

This template is using the `@openzeppelin/contracts-upgradeable` `v5.0.2` and `@openzeppelin/contracts` `v5.0.2` in order to be compatible with the VeChain Solidity compiler version of `0.8.20`.
