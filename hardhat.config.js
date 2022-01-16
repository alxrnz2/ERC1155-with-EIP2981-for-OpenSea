require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.2",

  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
    },
    mumbai: {
      url: "https://rpc-mumbai.maticvigil.com",
      accounts: ["<ADD WALLET PRIVATE KEY>"]
    },
    polygon: {
      url: "https://polygon-mainnet.infura.io/v3/<ADD API KEY>",
      accounts: ["<ADD WALLET PRIVATE KEY>"]
    },
    rinkeby: {
      url: "https://rinkeby.infura.io/v3/<ADD API KEY>",
      accounts: ["<ADD WALLET PRIVATE KEY>"]
    },
    ethereum: {
      url: "https://mainnet.infura.io/v3/<ADD API KEY>",
      accounts: ["<ADD WALLET PRIVATE KEY>"]
    }
  },

  etherscan: {
    // Your API key for Etherscan or Polygonscan
    apiKey: "<ADD API KEY>"
  },
};
