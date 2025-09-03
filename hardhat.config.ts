import hardhatToolboxMochaEthers from "@nomicfoundation/hardhat-toolbox-mocha-ethers";

import hardhatMarkup from "@solarity/hardhat-markup";

import type { HardhatUserConfig } from "hardhat/config";

const config: HardhatUserConfig = {
  plugins: [hardhatToolboxMochaEthers, hardhatMarkup],
  solidity: {
    version: "0.8.22",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      evmVersion: "paris",
    },
  },
  typechain: {
    outDir: "generated-types/ethers",
    discriminateTypes: true,
  },
};

export default config;
