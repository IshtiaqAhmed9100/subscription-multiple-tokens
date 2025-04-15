require("dotenv").config();
require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.25",
        settings: {
          viaIR: true,
          optimizer: {
            enabled: true,
            runs: 800,
          },
          evmVersion: "cancun",
        },
      },
    ],
  },
  networks: {
    mainnet: {
      url: process.env.URL_MAIN,
      accounts: [process.env.PRIVATE_KEY_MAIN],
    },
    sepolia: {
      url: process.env.URL_SEPOLIA,
      accounts: [process.env.PRIVATE_KEY_SEPOLIA],
    },
  },
  etherscan: {
    apiKey: "P53G8QUIVTNBERHPZHKGTGCKEDGSGJDE9B",
  },
};
