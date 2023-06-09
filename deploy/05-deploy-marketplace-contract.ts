import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import verify from "../utils/helper-functions";
import { networkConfig, developmentChains } from "../utils/helper-constants";
import { ethers } from "hardhat";

const deployBox: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  // @ts-ignore
  const { getNamedAccounts, deployments, network } = hre;
  const { deploy, log, get } = deployments;
  const { deployer } = await getNamedAccounts();
  const fischNftContract = await get("Fisch");
  log("----------------------------------------------------");
  log("Deploying Marketplace and waiting for confirmations...", fischNftContract.address);
  const marketplace = await deploy("Marketplace", {
    from: deployer,
    args: [fischNftContract.address],
    log: true,
    // we need to wait if on a live network so we can verify properly
    waitConfirmations: networkConfig[network.name].blockConfirmations || 1,
  });
  log(`Marketplace at ${marketplace.address}`);
  if (
    !developmentChains.includes(network.name) &&
    process.env.ETHERSCAN_API_KEY
  ) {
    await verify(marketplace.address, [fischNftContract.address]);
  }
  
};

export default deployBox;
deployBox.tags = ["all", "marketplace"];
