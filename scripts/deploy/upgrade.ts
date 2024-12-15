import { HttpNetworkConfig } from "hardhat/types";
import { EndorsersRewardDistributor } from "../../typechain-types";
import { upgradeProxy } from "../helpers";
import { network } from "hardhat";

async function main() {
  const contractAddress = "0xe781cd08cdd1c6d10a07a83ce42ef40880b94dfd";

  const networkConfig = network.config as HttpNetworkConfig;

  console.log(
    `Upgrading contract at address: ${contractAddress} on network ${network.name} (${networkConfig.url})`
  );

  const endorsersRewardDistributorV2 = (await upgradeProxy(
    "EndorsersRewardDistributor",
    "EndorsersRewardDistributor",
    contractAddress,
    [],
    {
      version: 2,
    }
  )) as EndorsersRewardDistributor;

  console.log(`EndorsersRewardDistributor upgraded`);

  // check that upgrade was successful
  const version = await endorsersRewardDistributorV2.version();
  console.log(`New EndorsersRewardDistributor version: ${version}`);

  if (parseInt(version) !== 2) {
    throw new Error(`EndorsersRewardDistributor version is not 2: ${version}`);
  }

  console.log("Execution completed");
  process.exit(0);
}

// Execute the main function
main();
