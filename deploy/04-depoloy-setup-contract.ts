import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const deployGovernor: DeployFunction = async (
  hre: HardhatRuntimeEnvironment
) => {
  const { deployments, getNamedAccounts, network } = hre;
  const { deploy, log, get } = deployments;
  const { deployer } = await getNamedAccounts();

  const governanceToken = await get("GovernanceToken");
  const timeLock = await get("TimeLock");
  const governor = await get("GovernanceCOntract");

};

export default deployGovernor;
