/**
 * Use this file to configure your truffle project. It's seeded with some
 * common settings for different networks and features like migrations,
 * compilation and testing. Uncomment the ones you need or modify
 * them to suit your project as necessary.
 *
 * More information about configuration can be found at:
 *
 * trufflesuite.com/docs/advanced/configuration
 *
 * To deploy via Infura you'll need a wallet provider (like @truffle/hdwallet-provider)
 * to sign your transactions before they're sent to a remote public node. Infura accounts
 * are available for free at: infura.io/register.
 *
 * You'll also need a mnemonic - the twelve word phrase the wallet uses to generate
 * public/private key pairs. If you're publishing your code to GitHub make sure you load this
 * phrase from a file you've .gitignored so it doesn't accidentally become public.
 *
 */
const path = require("path");
const filePath = path.join(__dirname, "../.env");
require("dotenv").config({ path: filePath });

const HDWalletProvider = require("@truffle/hdwallet-provider");
const verify = require("truffle-plugin-verify");

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: 5777,
    },
    rinkeby: {
      provider: () =>
        new HDWalletProvider(
          `${process.env.Deployer_Primary_key}`,
          `${process.env.ProvideRinkeby}`
        ),
      network_id: 4,
      gas: 7500000,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true,
    },
    mumbai: {
      provider: () =>
        new HDWalletProvider(
          `${process.env.Deployer_Primary_key}`,
          `${process.env.ProviderMumbai}`
        ),
      network_id: 80001,
      gas: 5500000,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true,
    },
  },
  plugins: ["truffle-plugin-verify"],
  api_keys: {
    etherscan: `${process.env.Etherscan_Key}`,
    polygonscan: `${process.env.Polygonscan_Key}`,
  },
  // Configure your compilers
  compilers: {
    solc: {
      version: "^0.8.0",
      //version: "0.6.2",
      // version: "0.5.1",    // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
       settings: {          // See the solidity docs for advice about optimization and evmVersion
      optimizer: {
        enabled: true,
        runs: 200,
      },
      //  evmVersion: "byzantium"
       }
    },
  },
};
