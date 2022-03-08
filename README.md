# meets-nft

# Truffle Development Environment for Windows and MacOS.

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
