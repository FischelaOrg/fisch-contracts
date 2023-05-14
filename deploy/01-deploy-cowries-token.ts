import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import verify from "../utils/helper-functions";
import { networkConfig, developmentChains } from "../utils/helper-constants";
import { ethers } from "hardhat"

const deployCowriesToken: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  // @ts-ignore
  const { getNamedAccounts, deployments, network } = hre
  const { deploy, log } = deployments
  const { deployer } = await getNamedAccounts()
  log("----------------------------------------------------")
  log("Deploying CowriesToken and waiting for confirmations...")
  const cowriesToken = await deploy("CowriesToken", {
    from: deployer,
    args: [],
    log: true,
    // we need to wait if on a live network so we can verify properly
    waitConfirmations: networkConfig[network.name].blockConfirmations || 1,
  })
  log(`CowriesToken at ${cowriesToken.address}`)
  if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
    await verify(cowriesToken.address, [])
  }
  log(`Delegating to ${deployer}`)
  await delegate(cowriesToken.address, deployer)
  log("Delegated!")
}

const delegate = async (cowriesTokenAddress: string, delegatedAccount: string) => {
  const cowriesToken = await ethers.getContractAt("CowriesToken", cowriesTokenAddress)
  const transactionResponse = await cowriesToken.delegate(delegatedAccount)
  await transactionResponse.wait(1)
  console.log(`Checkpoints: ${await cowriesToken.numCheckpoints(delegatedAccount)}`)
}

export default deployCowriesToken
deployCowriesToken.tags = ["all", "villagesquare"]
