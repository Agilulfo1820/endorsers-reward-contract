import { ethers } from "hardhat";
import {
  EndorsersRewardDistributor,
  SimpleStorage,
} from "../../typechain-types";
import { deployProxy } from "./upgrades";

interface DeployInstance {
  owner: any;
  otherAccount: any;
  otherAccounts: any[];
  endorsersRewardDistributorContract: EndorsersRewardDistributor;
}

let cachedDeployInstance: DeployInstance | undefined = undefined;

export const getOrDeployContractInstances = async ({
  forceDeploy = false,
  printLogs = false,
}) => {
  if (!forceDeploy && cachedDeployInstance !== undefined) {
    return cachedDeployInstance;
  }

  const [deployer, otherAccount, ...otherAccounts] = await ethers.getSigners();

  printLogs && console.log("Deployer address", deployer.address);

  printLogs && console.log("Deploying EndorsersRewardDistributor contract");

  const endorsersRewardDistributorContract = (await deployProxy(
    "EndorsersRewardDistributor",
    [
      {
        upgrader: deployer.address,
        admin: deployer.address,
        appId:
          "0x899de0d0f0b39e484c8835b2369194c4c102b230c813862db383d44a4efe14d3",
        allocationVotingGovernor: "0x89A00Bb0947a30FF95BEeF77a66AEdE3842Fe5B7",
        rewardsPool: "0x6Bee7DDab6c99d5B2Af0554EaEA484CE18F52631",
        x2earnApps: "0x8392B7CCc763dB03b47afcD8E8f5e24F9cf0554D",
        allocationPool: "0x4191776F05f4bE4848d3f4d587345078B439C7d3",
        startRound: 22,
        rewardsPercentage: 5,
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
