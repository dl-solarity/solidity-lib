import "@nomiclabs/hardhat-web3";
import "@nomiclabs/hardhat-truffle5";
import "@nomicfoundation/hardhat-ethers";
import "@nomicfoundation/hardhat-chai-matchers";
import "@solarity/hardhat-markup";
import "@typechain/hardhat";
import "hardhat-contract-sizer";
import "hardhat-gas-reporter";
import "solidity-coverage";
import "tsconfig-paths/register";

import { HardhatUserConfig } from "hardhat/config";

import * as dotenv from "dotenv";
dotenv.config();

function typechainTarget() {
  const target = process.env.TYPECHAIN_TARGET;

  return target === "" || target === undefined ? "ethers-v6" : target;
}

function forceTypechain() {
  return process.env.TYPECHAIN_FORCE === "false";
}

const config: HardhatUserConfig = {
  networks: {
    hardhat: {
      initialDate: "1970-01-01T00:00:00Z",
    },
    localhost: {
      url: "http://127.0.0.1:8545",
      initialDate: "1970-01-01T00:00:00Z",
      gasMultiplier: 1.2,
    },
  },
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      evmVersion: "paris",
    },
  },
  markup: {
    onlyFiles: ["./contracts/"],
  },
  mocha: {
    timeout: 1000000,
  },
  contractSizer: {
    alphaSort: false,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: false,
  },
  gasReporter: {
    currency: "USD",
    gasPrice: 50,
    enabled: false,
    coinmarketcap: `${process.env.COINMARKETCAP_KEY}`,
  },
  typechain: {
    outDir: `generated-types/${typechainTarget().split("-")[0]}`,
    target: typechainTarget(),
    alwaysGenerateOverloads: true,
    discriminateTypes: true,
    dontOverrideCompile: forceTypechain(),
  },
};

export default config;
