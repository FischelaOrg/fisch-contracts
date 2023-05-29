import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import {
  ADDRESS_ZERO,
} from "../utils/helper-constants";
import { ethers } from "hardhat"

const setupContracts: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  // @ts-ignore
  const { getNamedAccounts, deployments, network } = hre
  const { log } = deployments
  const { deployer } = await getNamedAccounts()
  const governanceToken = await ethers.getContract("CowriesToken", deployer)
  const lockController = await ethers.getContract("LockController", deployer)
  const governor = await ethers.getContract("VillageSquare", deployer)

  log("----------------------------------------------------")
  log("Setting up contracts for roles...")
  // would be great to use multicall here...
  const proposerRole = await lockController.PROPOSER_ROLE()
  const executorRole = await lockController.EXECUTOR_ROLE()
  const adminRole = await lockController.TIMELOCK_ADMIN_ROLE()

  const proposerTx = await lockController.grantRole(proposerRole, governor.address)
  await proposerTx.wait(1)
  const executorTx = await lockController.grantRole(executorRole, ADDRESS_ZERO)
  await executorTx.wait(1)
  const revokeTx = await lockController.revokeRole(adminRole, deployer)
  await revokeTx.wait(1)
  // Guess what? Now, anything the timelock wants to do has to go through the governance process!
}

export default setupContracts
setupContracts.tags = ["all", "setup"]
