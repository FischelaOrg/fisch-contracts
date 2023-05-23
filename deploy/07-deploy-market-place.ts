import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import verify from "../utils/helper-functions"
import { networkConfig, developmentChains } from "../utils/helper-constants"

const deployMarketplace: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    // @ts-ignore
    const { getNamedAccounts, deployments, network } = hre
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    log("----------------------------------------------------")
    log("Deploying Marketplace and waiting for confirmations...")
    const marketPlace = await deploy("Marketplace", {
        from: deployer,
        args: [],
        log: true,
        // we need to wait if on a live network so we can verify properly
        waitConfirmations: networkConfig[network.name].blockConfirmations || 1,
      })
      log(`Marketplace at ${marketPlace.address}`)
      if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        await verify(marketPlace.address, [])
      }    
}

export default deployMarketplace
deployMarketplace.tags = ["all", "marketplace"]