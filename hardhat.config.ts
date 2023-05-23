import "@typechain/hardhat";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-ethers";
import "hardhat-gas-reporter";
import "dotenv/config";
import "solidity-coverage";
import "hardhat-deploy";
import { HardhatUserConfig } from "hardhat/config";

const COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY || "";
const MUMBAI_RPC_URL =
  process.env.MUMBAI_RPC_URL ||
  "https://matic-mumbai.chainstacklabs.com/";
  const POLYGON_MAINNET_RPC =
  process.env.POLYGON_MAINNET_RPC ||
  "https://matic-mumbai.chainstacklabs.com/";

const PRIVATE_KEY = process.env.PRIVATE_KEY || "privatKey";
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "";

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      chainId: 31337,
      allowUnlimitedContractSize: true,
    },
    localhost: {
      chainId: 31337,
      allowUnlimitedContractSize: true,
    },
    mumbai: {
      url: MUMBAI_RPC_URL,
      accounts: [PRIVATE_KEY],
      chainId: 80001,
    },
    polygon: {
      url: POLYGON_MAINNET_RPC,
      accounts: [PRIVATE_KEY],
      chainId: 137,
    },
  },
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  // etherscan: {
  //   apiKey: ETHERSCAN_API_KEY,
  // },
  // gasReporter: {
  //   enabled: true,
  //   currency: "USD",
  //   outputFile: "gas-report.txt",
  //   noColors: true,
  //   // coinmarketcap: COINMARKETCAP_API_KEY,
  // },

  paths: {
    // Specify the test directory
    tests: "./test",
  },

  namedAccounts: {
    deployer: {
      default: 0,
    },
    liquidator: {
      default: 1,
    },
    borrower: {
      default: 2,
    },
  },
  mocha: {
    timeout: 200000, // 200 seconds max for running tests
  },
};

export default config;
