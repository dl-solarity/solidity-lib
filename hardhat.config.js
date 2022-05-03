require("@nomiclabs/hardhat-web3");
require("@nomiclabs/hardhat-truffle5");
require("@nomiclabs/hardhat-etherscan");
require("hardhat-contract-sizer");
require("hardhat-gas-reporter");

const dotenv = require("dotenv");
dotenv.config();

module.exports = {
  networks: {
    hardhat: {
      initialDate: "1970-01-01T00:00:00Z",
    },
    localhost: {
      url: "http://127.0.0.1:8545",
      initialDate: "1970-01-01T00:00:00Z",
      gasMultiplier: 1.2,
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
      gasMultiplier: 1.2,
    },
    chapel: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
      gasMultiplier: 1.2,
      timeout: 50000,
    },
    bsc_mainnet: {
      url: "https://bsc-dataseed.binance.org/",
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
      gasMultiplier: 1.2,
    },
    eth_mainnet: {
      url: `https://mainnet.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
      gasMultiplier: 1.2,
    },
  },
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  etherscan: {
    apiKey: `${process.env.ETHERSCAN_KEY}`,
  },
  mocha: {
    timeout: 1000000,
  },
  contractSizer: {
    alphaSort: false,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true,
  },
  gasReporter: {
    currency: "USD",
    gasPrice: 50,
    enabled: false,
    coinmarketcap: `${process.env.COINMARKETCAP_KEY}`,
  },
};
