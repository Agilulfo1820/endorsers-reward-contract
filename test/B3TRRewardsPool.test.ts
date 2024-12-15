import { ethers } from "hardhat";
import { expect } from "chai";
import { getOrDeployContractInstances } from "../scripts/helpers";
import { describe, it } from "mocha";
import { ZeroAddress, ZeroHash } from "ethers";
import { deployProxyOnly, initializeProxy } from "../scripts/helpers";

describe("B3TR Rewards Pool", function () {
  describe("Deployment", () => {
    it("Contract should deploy successfully", async () => {
      const { simpleStorageContract } = await getOrDeployContractInstances({
        forceDeploy: true,
      });

      // check that the contract is deployed
      expect(await simpleStorageContract.getAddress()).to.not.equal(
        ZeroAddress
      );

      // check that the value is 0
      expect(await simpleStorageContract.getValue()).to.equal(0);
    });
  });

  describe("Can read and set value", () => {
    it("Can read and set value", async () => {
      const { simpleStorageContract, owner } =
        await getOrDeployContractInstances({
          forceDeploy: true,
        });

      // set the value to 42
      await simpleStorageContract.connect(owner).setValue(42);

      // check that the value is 42
      expect(await simpleStorageContract.getValue()).to.equal(42);
    });
  });
});
