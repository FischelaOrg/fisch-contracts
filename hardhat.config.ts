import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-deploy";
import "@nomiclabs/hardhat-ethers";
import "@typechain/hardhat";

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",

  networks: {
    hardhat: {
      chainId: 31337,
    },

    localhost: {
      chainId: 31337,
    },
    
    rinkeby: {
      url: "https://rinkeby.infura.io/v3/YOUR_INFURA_PROJECT_ID",
      // accounts: [`0x${YOUR_PRIVATE_KEY}`],
    },
  },

  namedAccounts: {
    deployer: {
      default: 0,
    },
    player: {
      default: 1,
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.8",
      },
      {
        version: "0.8.9",
      },
    ],
  },
  etherscan: {
    apiKey: "YOUR_ETHERSCAN_API_KEY",
  },
};

export default config;
