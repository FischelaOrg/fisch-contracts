import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import {
  quorumPercentage,
  votingDelay,
  votingPeriod,
} from "../util/deploy-helper";

const deployGovernor: DeployFunction = async (
  hre: HardhatRuntimeEnvironment
) => {
  const { deployments, getNamedAccounts, network } = hre;
  const { deploy, log, get } = deployments;
  const { deployer } = await getNamedAccounts();

  const governanceToken = await get("GovernanceToken");
  const timeLock = await get("TimeLock");

  const governor = await deploy("GovernanceCOntract", {
    from: deployer,
    args: [
      governanceToken.address,
      timeLock.address,
      votingDelay,
      votingPeriod,
      quorumPercentage,
    ],
    log: true,
  });

  console.log(`Deployed contract to ${governor.address}`);
};

export default deployGovernor;
