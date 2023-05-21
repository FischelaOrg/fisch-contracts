import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import verify from "../utils/helper-functions"
import { networkConfig, developmentChains } from "../utils/helper-constants"

const deployFisch: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    // @ts-ignore
    const { getNamedAccounts, deployments, network } = hre
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    log("----------------------------------------------------")
    log("Deploying Fisch and waiting for confirmations...")
    const fisch = await deploy("Fisch", {
        from: deployer,
        args: [],
        log: true,
        // we need to wait if on a live network so we can verify properly
        waitConfirmations: networkConfig[network.name].blockConfirmations || 1,
      })
      log(`TimeLock at ${fisch.address}`)
      if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        await verify(fisch.address, [])
      }    
}

export default deployFisch
deployFisch.tags = ["all", "fisch"]