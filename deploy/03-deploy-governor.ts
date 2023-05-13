import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import {
  VOTING_DELAY,
  VOTING_PERIOD,
  QUORUM_PERCENTAGE,
} from "../util/deploy-helper";
import { ethers } from "hardhat";

const deployGovernor: DeployFunction = async (
  hre: HardhatRuntimeEnvironment
) => {
    const { deployments, getNamedAccounts, network } = hre;
    const { deploy, log, get } = deployments;
    const { deployer } = await getNamedAccounts();

    const governanceToken = await get("GovernanceToken");
    log(governanceToken.address, "HUSH GOVERNANCE");

    const timeLock = await get("TimeLock");
    log(timeLock.address, "HUSH TIMELOCK");

    const governor = await deploy("GovernorContract", {
      from: deployer,
      args: [
        governanceToken.address,
        timeLock.address,
        VOTING_DELAY,
        VOTING_PERIOD,
        QUORUM_PERCENTAGE,
      ],
      log: false,
      gasLimit: 10000000
    });

    log(`Deployed contract to ${governor.address}`);
 
};

export default deployGovernor;
