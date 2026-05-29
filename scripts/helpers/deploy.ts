import { ethers, network } from "hardhat";
import { EndorsersRewardDistributor } from "../../typechain-types";
import { deployProxy } from "./upgrades";

interface DeployInstance {
  owner: any;
  otherAccount: any;
  otherAccounts: any[];
  endorsersRewardDistributorContract: EndorsersRewardDistributor;
}

// VeBetterDAO contract addresses per network. Mainnet/testnet values are stable
// across X2Earn apps and can be overridden via env vars if you need to point at
// a custom deployment (e.g. a fork or staging environment).
const VEBETTERDAO_ADDRESSES: Record<
  string,
  {
    allocationVotingGovernor: string;
    rewardsPool: string;
    x2earnApps: string;
    allocationPool: string;
  }
> = {
  vechain_mainnet: {
    allocationVotingGovernor: "0x89A00Bb0947a30FF95BEeF77a66AEdE3842Fe5B7",
    rewardsPool: "0x6Bee7DDab6c99d5B2Af0554EaEA484CE18F52631",
    x2earnApps: "0x8392B7CCc763dB03b47afcD8E8f5e24F9cf0554D",
    allocationPool: "0x4191776F05f4bE4848d3f4d587345078B439C7d3",
  },
  vechain_testnet: {
    allocationVotingGovernor: "0x8800592c463f0b21ae08732559ee8e146db1d7b2",
    rewardsPool: "0x2d2a2207c68a46fc79325d7718e639d1047b0d8b",
    x2earnApps: "0x0b54a094b877a25bdc95b4431eaa1e2206b1ddfe",
    allocationPool: "0x6f7b4bc19b4dc99005b473b9c45ce2815bbe7533",
  },
  // For solo / forks, set the four VeBetterDAO addresses explicitly via env
  // vars — see .env.example.
};

let cachedDeployInstance: DeployInstance | undefined = undefined;

const requireEnv = (name: string): string => {
  const v = process.env[name];
  if (!v || v.trim() === "") {
    throw new Error(`Missing required env var: ${name}`);
  }
  return v.trim();
};

const optionalEnv = (name: string, fallback?: string): string | undefined => {
  const v = process.env[name];
  if (!v || v.trim() === "") return fallback;
  return v.trim();
};

export const getOrDeployContractInstances = async ({
  forceDeploy = false,
  printLogs = false,
}) => {
  if (!forceDeploy && cachedDeployInstance !== undefined) {
    return cachedDeployInstance;
  }

  const [deployer, otherAccount, ...otherAccounts] = await ethers.getSigners();

  printLogs && console.log("Deployer address", deployer.address);

  const networkDefaults = VEBETTERDAO_ADDRESSES[network.name];

  const appId = requireEnv("APP_ID");
  const startRound = Number(requireEnv("START_ROUND"));
  const rewardsPercentage = Number(requireEnv("REWARDS_PERCENTAGE"));

  const admin = optionalEnv("ADMIN_ADDRESS", deployer.address)!;
  const upgrader = optionalEnv("UPGRADER_ADDRESS", deployer.address)!;
  const vetDomainOwner = optionalEnv("VET_DOMAIN_OWNER", deployer.address)!;

  const allocationVotingGovernor = optionalEnv(
    "ALLOCATION_VOTING_GOVERNOR",
    networkDefaults?.allocationVotingGovernor
  );
  const rewardsPool = optionalEnv("REWARDS_POOL", networkDefaults?.rewardsPool);
  const x2earnApps = optionalEnv("X2EARN_APPS", networkDefaults?.x2earnApps);
  const allocationPool = optionalEnv(
    "ALLOCATION_POOL",
    networkDefaults?.allocationPool
  );

  if (
    !allocationVotingGovernor ||
    !rewardsPool ||
    !x2earnApps ||
    !allocationPool
  ) {
    throw new Error(
      `No VeBetterDAO defaults for network "${network.name}". Set ALLOCATION_VOTING_GOVERNOR, REWARDS_POOL, X2EARN_APPS, ALLOCATION_POOL in your env.`
    );
  }

  if (printLogs) {
    console.log("Deploying EndorsersRewardDistributor with params:");
    console.log({
      network: network.name,
      admin,
      upgrader,
      vetDomainOwner,
      appId,
      startRound,
      rewardsPercentage,
      allocationVotingGovernor,
      rewardsPool,
      x2earnApps,
      allocationPool,
    });
  }

  const endorsersRewardDistributorContract = (await deployProxy(
    "EndorsersRewardDistributor",
    [
      {
        upgrader,
        admin,
        vetDomainOwner,
        appId,
        allocationVotingGovernor,
        rewardsPool,
        x2earnApps,
        allocationPool,
        startRound,
        rewardsPercentage,
      },
    ],
    {},
    true,
    undefined
  )) as EndorsersRewardDistributor;

  printLogs &&
    console.log(
      `EndorsersRewardDistributor contract deployed at ${await endorsersRewardDistributorContract.getAddress()}`
    );

  cachedDeployInstance = {
    owner: deployer,
    otherAccount,
    otherAccounts,
    endorsersRewardDistributorContract,
  };
  return cachedDeployInstance as DeployInstance;
};
