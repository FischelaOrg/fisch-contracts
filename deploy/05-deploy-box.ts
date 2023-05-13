import { ethers } from "hardhat";
import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { ADDRESS_ZERO } from "../util/deploy-helper";

const deployBox: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, getNamedAccounts, network } = hre;
  const { deploy, log, get } = deployments;
  const { deployer } = await getNamedAccounts();
  log(`Deploying Box...`);

  const box = await deploy("Box", {
    from : deployer,
    args: [],
    log: true
  });

  const timeLock = await ethers.getContract("TimeLock")
  const boxContract = await ethers.getContractAt("Box", box.address)

  const boxTxn = await boxContract.tansferOwnership(timeLock.address)
  await boxTxn.wait(1)

  log("Ownership Transfered!")

};
