# Endorsers Reward Distributor

This contract is responsible for distributing rewards (from previous round) to endorsers.
The percentage of the reward is fixed, but can be set by the admin.
Rewards can be distributed only once per round.
Rewards amount is calculated based on the tier of their X-Node.
Rewards are distributed through the `X2EarnRewardsPool` contract.

The distributeRewards function is called by a scheduled job on Vechain.Energy.

## Mainnet Address

0xe781cd08cdd1c6d10a07a83ce42ef40880b94dfd

## Admin Address

0x6B020E5C8E8574388a275cC498B27E3EB91ec3f2 (cleanify.vet)

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
