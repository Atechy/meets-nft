# meets-nft

This is the smart contract for MeetsMeta passes nfts. this is based on ERC721
and supports the following features:

## Features

### Limits

each wallet can only mint 3 tokens on whitelist and 3 additional on public.

### Pricing

prices are fixed to 0.16 eth for public and 0.11 eth for whitelisted wallets.

whitelist and public sales are two separate events.

### Tiers

5 tiers are defined on the system with max supply of 4888

### Partners Payout

On the deployment of the smart contract the owner can specify 3 other accounts:

1- Builder which will receive 10% of all revenue generated from selling NFTs

2- MarketingA will receive 2% of all sales.

3- MarketingB will receive 4% of all sales.

The rest will be accounted for the contract owner.

The wallets addresses should be specified on deployment and cannot be changed.

These additional accounts can request an early payout at any point, or wait until the owner invoke the swipeOut function which will transfer all the balances and then take whatever remains to his/her wallet.

### Whitelisting

The owner of the contract can invoke the whitelistAddress() function and add addresses to the whitelist which will be able to mint passes at 0.2eth instead of 0.34eth

whitelisted addresses will be able to mint up to 5 passes "still pending"

beside the on chain whitelist users mainly going to be using off chain whitelist with signature verification.

### Dynamic token URI

The NFTs image urls can be changed at later stage by using the setBaseURI method.

### Reveal Event

the reveal will be managed by assigning IPFS gateway to the image url.

### Royalties

Reselling royalties should be set on the Marketplaces on listing.

## Truffle Development Environment for Windows and MacOS

This document is for setting up a Development Environment on Windows and MacOS to deploy a simple HelloWorld smart contract coded in **Solidity** using **Truffle framework** for **Ethereum** based Blockchain.

## Version

Truffle v5.4.31 (core: 5.4.31)

Solidity v0.5.16 (solc-js)

Node v16.13.2

**If you get any errors installing latest version of truffle please use npm version 6.14.16.**

Npm 6.14.16

```bash
npm install -g npm@6
```

Web3.js v1.5.3

## Requirements

[Install](https://nodejs.org/en/) Node JS and NPM.

Install [Truffle Framework](https://trufflesuite.com/index.html).

```bash
npm install -g truffle
```

## Deploy

Clone this repository and cd into it.

On Windows use PowerShell with administrator privileges.

Run "truffle version" and "node -v" to check for current version.

```bash
truffle version
```

```bash
node -v
```

To deploy the smart contract to the ganache core ethereum development node bundled with truffle start the development mode of truffle in powershell

```bash
truffle develop
```

Run,

```bash
migrate --reset
```
