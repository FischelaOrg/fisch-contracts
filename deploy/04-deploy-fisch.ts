import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import verify from "../utils/helper-functions"
import { networkConfig, developmentChains } from "../utils/helper-constants"
import { ethers } from "hardhat"

const deployFisch: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    // @ts-ignore
    const { getNamedAccounts, deployments, network } = hre
    const { deploy, log, get } = deployments
    const { deployer } = await getNamedAccounts()
    const timelock = await ethers.getContract("TimeLock", deployer);
    log("----------------------------------------------------")
    log("Deploying Fisch and waiting for confirmations...")
    
    const fisch = await deploy("Fisch", {
        from: deployer,
        args: [],
        log: true,
        // we need to wait if on a live network so we can verify properly
        waitConfirmations: networkConfig[network.name].blockConfirmations || 1,
      })
      log(`TimeLock at ${timelock.address}`)

      const fischContract = await ethers.getContractAt("Fisch", fisch.address)
      await fischContract.transferOwnership(timelock.address)

      if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        await verify(fisch.address, [])
      }    
}

export default deployFisch
deployFisch.tags = ["all", "fisch"]