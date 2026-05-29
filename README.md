# X2Earn Endorsers Reward Distributor

A generic, upgradeable contract that any [VeBetterDAO](https://vebetterdao.org)
X2Earn app can deploy to share a fixed percentage of each round's app rewards
with its endorsers, weighted by the endorsement score of each endorser's
X-Node.

Rewards are distributed through the `X2EarnRewardsPool`, once per round, and
can be triggered permissionlessly (typically via a scheduled job — for example
on [vechain.energy](https://vechain.energy)).

## How it works

1. After an allocation round closes, anyone calls `distributeRewards()`.
2. The contract reads your app's earnings for that round from `XAllocationPool`.
3. It takes `rewardsPercentage` of those earnings as the endorser pool.
4. It fetches your app's endorsers from `X2EarnApps` and weights each share by
   that endorser's `getUsersEndorsementScore` (their X-Node tier).
5. It calls `X2EarnRewardsPool.distributeRewardDeprecated` once per endorser.

Rewards for a given round can only be distributed once.

## Deploying your own instance

### 1. Install

```bash
nvm use            # node v20
yarn install
```

### 2. Configure

```bash
cp .env.example .env
```

Edit `.env` and set at least:

- `MNEMONIC` — the deployer wallet
- `APP_ID` — your X2Earn app id (bytes32)
- `START_ROUND` — the last completed round you do NOT want included
- `REWARDS_PERCENTAGE` — share of each round's earnings to endorsers (0-100)

Optional:

- `ADMIN_ADDRESS`, `UPGRADER_ADDRESS`, `VET_DOMAIN_OWNER` — default to the
  deployer if not set. `VET_DOMAIN_OWNER` is the address returned by `owner()`
  and is used to claim a `.vet` subdomain for the contract.
- `ALLOCATION_VOTING_GOVERNOR`, `REWARDS_POOL`, `X2EARN_APPS`,
  `ALLOCATION_POOL` — mainnet and testnet defaults are baked into the deploy
  script. Only needed for solo / forks or to override.

### 3. Deploy

```bash
yarn deploy:mainnet     # or :testnet, :solo
```

The proxy address is printed at the end. Save it.

### 4. Authorize the contract as a reward distributor

In the VeBetterDAO X2Earn admin UI (or by calling `X2EarnApps` directly),
add the deployed proxy address as a reward distributor for your app. Without
this, `distributeRewards()` will revert.

### 5. Fund the rewards pool

The `X2EarnRewardsPool` must hold enough B3TR for your app to cover the
endorser share each round. Top it up the same way you do for any other reward
distribution.

### 6. Schedule distribution

Set up a job (e.g. on vechain.energy) to call `distributeRewards()` once per
round, after the previous round closes.

## Upgrading

```bash
PROXY_ADDRESS=0x... yarn upgrade:mainnet
```

The deployer must hold `UPGRADER_ROLE` on the proxy.

## Local development

Start a Thor-Solo node:

```bash
yarn start-solo
```

Compile, test, and deploy:

```bash
yarn compile
yarn test
yarn deploy:solo
```

Generate docs:

```bash
yarn generate-docs
```

## Admin operations

- `setRewardsPercentage(uint256)` — change the endorser share. `DEFAULT_ADMIN_ROLE`.
- `setVetDomainOwner(address)` — change the address returned by `owner()`.
  `DEFAULT_ADMIN_ROLE`.

## Compatibility

Built against OpenZeppelin Contracts `5.0.2` (upgradeable + non-upgradeable) to
match the VeChain Solidity compiler version `0.8.20`.

## License

MIT
