import hardhatToolboxMochaEthers from "@nomicfoundation/hardhat-toolbox-mocha-ethers";

import hardhatMarkup from "@solarity/hardhat-markup";

import type { HardhatUserConfig } from "hardhat/config";

import hardhatContractSizer from "@solidstate/hardhat-contract-sizer";

const config: HardhatUserConfig = {
  plugins: [hardhatToolboxMochaEthers, hardhatMarkup, hardhatContractSizer],
  solidity: {
    compilers: [
      {
        version: "0.8.22",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
          evmVersion: "paris",
        },
      },
      {
        version: "0.8.28",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  typechain: {
    outDir: "generated-types/ethers",
    discriminateTypes: true,
  },
  contractSizer: {
    alphaSort: false,
    runOnCompile: true,
    strict: false,
    flat: true,
  },
};

export default config;
