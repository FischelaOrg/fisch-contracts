import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { minDelay } from "../util/deploy-helper";

const deployTimeLock: DeployFunction = async (
  hre: HardhatRuntimeEnvironment
) => {
  const { deployments, getNamedAccounts, network } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy, log } = deployments;

  const timeLock = await deploy("TimeLock", {
    from: deployer,
    args: [minDelay, [], [], deployer],
    log: true,
  });

  log(`Timelock deployed to ${timeLock.address}`);
};

export default deployTimeLock;
