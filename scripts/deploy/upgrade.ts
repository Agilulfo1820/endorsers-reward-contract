import { HttpNetworkConfig } from "hardhat/types";
import { EndorsersRewardDistributor } from "../../typechain-types";
import { upgradeProxy } from "../helpers";
import { network } from "hardhat";

async function main() {
  const contractAddress = process.env.PROXY_ADDRESS?.trim();
  if (!contractAddress) {
    throw new Error(
      "Missing PROXY_ADDRESS env var — set it to the deployed EndorsersRewardDistributor proxy address you want to upgrade."
    );
  }

  const networkConfig = network.config as HttpNetworkConfig;

  console.log(
    `Upgrading contract at address: ${contractAddress} on network ${network.name} (${networkConfig.url})`
  );

  const upgraded = (await upgradeProxy(
    "EndorsersRewardDistributor",
    "EndorsersRewardDistributor",
    contractAddress,
    [],
    {}
  )) as EndorsersRewardDistributor;

  console.log(`EndorsersRewardDistributor upgraded`);

  const version = await upgraded.version();
  console.log(`New EndorsersRewardDistributor version: ${version}`);

  console.log("Execution completed");
  process.exit(0);
}

main();
