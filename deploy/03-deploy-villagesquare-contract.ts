import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import verify from "../utils/helper-functions";
import {
  networkConfig,
  developmentChains,
  QUORUM_PERCENTAGE,
  VOTING_PERIOD,
  VOTING_DELAY,
} from "../utils/helper-constants";

const deployVillageSquareContract: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  // @ts-ignore
  const { getNamedAccounts, deployments, network } = hre;
  const { deploy, log, get } = deployments;
  const { deployer } = await getNamedAccounts();
  const cowriesToken = await get("CowriesToken");
  const timeLock = await get("TimeLock");
  const args = [
    cowriesToken.address,
    timeLock.address,
    QUORUM_PERCENTAGE,
    VOTING_PERIOD,
    VOTING_DELAY,
  ];

  log("----------------------------------------------------");
  log("Deploying VillageSquare and waiting for confirmations...");
  const villageSquareContract = await deploy("VillageSquare", {
    from: deployer,
    args,
    log: true,
    // we need to wait if on a live network so we can verify properly
    waitConfirmations: networkConfig[network.name].blockConfirmations || 1,
  });
  log(`Village Square at ${villageSquareContract.address}`);
  if (
    !developmentChains.includes(network.name) &&
    process.env.ETHERSCAN_API_KEY
  ) {
    await verify(villageSquareContract.address, args);
  }
};

export default deployVillageSquareContract;
deployVillageSquareContract.tags = ["all", "villagesquare"];
