const MeetsWorld = artifacts.require('./MeetsWorld.sol');
require('dotenv').config();
const chalk = require('chalk');
const log = console.log;

const BUILDER = process.env.BUILDER
const MARKETINGA = process.env.MARKETINGA
const MARKETINGB = process.env.MARKETINGB

contract('MeetsWorld', (accounts) => {

    // fetch accounts on different index
    let [OWNER, bob, Usman, Imaad] = accounts;
    let MeetsWorldContract;

    beforeEach(async () => {
        log(`
        Contract deployed by ${chalk.yellow.bold('OWNER')}(${chalk.green(OWNER)})          
        ${chalk.yellow.bold('BUILDER')} Address:-${chalk.green(BUILDER)}             
        ${chalk.yellow.bold('MARKETINGA')} Address:-${chalk.green(MARKETINGA)}           
        ${chalk.yellow.bold('MARKETINGB')} Address:-${chalk.green(MARKETINGB)}
    `)

        MeetsWorldContract = await MeetsWorld.new(
            BUILDER,
            MARKETINGA,
            MARKETINGB
        );
    });

    it('Mint passes at normal price---', async () => {
        log(`
                             Minting Start...
                    `);
        log(`
        --------------------------------------------------------------------------
        `);
        log(`
        ${chalk.yellow.bold('BOB')}(${chalk.green(bob)}) Mint a NFT.
                    `);

        await mint(bob, false)
        await details(0)

        log(`
        --------------------------------------------------------------------------
                `);
        log(`
        ${chalk.yellow.bold('USMAN')}(${chalk.green(Usman)}) Mint a NFT.
               `);

        await mint(Usman, false)
        await details(1)

        log(`
        --------------------------------------------------------------------------
                `);
    });

    it('Mint passes at discounted price---', async () => {
        log(`
        Adding ${chalk.yellow.bold('BOB')}(${chalk.green(bob)}) and
        ${chalk.yellow.bold('USMAN')}(${chalk.green(Usman)}) in 
        WhiteListed List By Owner ${chalk.yellow.bold('OWNER')}(${chalk.green(OWNER)})
        `)
        log(`
        --------------------------------------------------------------------------
        `);
        await mint(bob, true)
        await details(0)
        log(`
        --------------------------------------------------------------------------
                `);
        await mint(Usman, true)
        await details(1)

    });

    it('Partner request rayout---', async () => {

        await mintSomeNFT()

        await requestPayout('OWNER', OWNER)
        await requestPayout('BUILDER', BUILDER)
        await requestPayout('MARKETINGA', MARKETINGA)
        await requestPayout('MARKETINGB', MARKETINGB)
    });

    it('Owner swipeOut for all partners---', async () => {

        await mintSomeNFT()

        await checkBalance('OWNER', OWNER, "before")
        await checkBalance('BUILDER', BUILDER, "before")
        await checkBalance('MARKETINGA', MARKETINGA, "before")
        await checkBalance('MARKETINGB', MARKETINGB, "before")

        log(`
        swipOut running by Admin....
        `)
        await MeetsWorldContract.swipOut()

        await checkBalance('OWNER', OWNER, "after")
        await checkBalance('BUILDER', BUILDER, "after")
        await checkBalance('MARKETINGA', MARKETINGA, "after")
        await checkBalance('MARKETINGB', MARKETINGB, "after")

    });


    it('Fetch toeknURI', async () => {

        let beforeReveal = await MeetsWorldContract.tokenURI(1)

        log(`
        Before Reveal 
        ${chalk.green(beforeReveal)}
        Default URL set in smart contract.

        Minting 1 NFT..
      `)
        await mint(Usman, true)
        await MeetsWorldContract.revealCollection(true)
        await MeetsWorldContract.setBaseURI("https://meetsWorld.com/assets/")
        let afterReveal = await MeetsWorldContract.tokenURI(1)
        log(`
        After Revealing and SetURL
        ${chalk.green(afterReveal)}
      `)

    })

    //Functions

    async function mintSomeNFT() {

        log(chalk.blue.bold(`
                Before swipeOut First we have to mint some NFT's.
            `))
        log(` 
        Minting NFT's by ${chalk.yellow.bold('BOB')}(${chalk.green(bob)}),
        ${chalk.yellow.bold('USMAN')}(${chalk.green(Usman)}) at Normal Rate.
        `)

        await mint(bob, false)
        await mint(Usman, false)

        log(`
        Minting NFT by ${chalk.yellow.bold('IMAAD')}(${chalk.green(Imaad)})
        at discount rate.
        `)
        log(`
        Adding ${chalk.yellow.bold('IMAAD')}(${chalk.green(Imaad)}) in Whitelisted list...
        `)

        await mint(Imaad, true)
    }

    async function details(index) {
        let assignCat = await MeetsWorldContract.assignedCategories(index)
        log(`
        Owner:-${chalk.green(assignCat.addr)}
        TokenId:-${chalk.green(assignCat.tokenId.toNumber())}
        Categories:-${chalk.green(assignCat.rarityLevel.toNumber())}
                     `)
    }

    async function mint(userAddress, discounted) {

        let mintingPrice = process.env.NORMAL_PRICE
        if (discounted) {
            await MeetsWorldContract.whitelistAddress([userAddress])
            mintingPrice = process.env.DISCOUNTED_PRICE
        }
        //mint
        let res = await MeetsWorldContract.mintPasses.sendTransaction(
            process.env.TOKEN_URI, {
                value: web3.utils.toWei(mintingPrice, 'ether'),
                from: userAddress
            }
        );
        log(`
        Transaction Hash:-${chalk.green(res.receipt.transactionHash)}
        `)
    }

    async function requestPayout(partnerName, partnerAddress) {
        log(`
        --------------------------------------------------------------------------
            `);

        log(`
        ${chalk.yellow.bold(partnerName)}(${chalk.green(partnerAddress)}) share till now is: ${chalk.green(await MeetsWorldContract.partnerBalances(partnerAddress)/1e18)} ether.
        `)

        await checkBalance(partnerName, partnerAddress, "before")

        log(`
        Request Payout by ${chalk.yellow.bold(partnerName)}...
        `)


        await MeetsWorldContract.requestPayout({
            from: partnerAddress
        })

        await checkBalance(partnerName, partnerAddress, "after")
    }

    async function checkBalance(partnerName, partnerAddress, payOutType) {

        log(`
        ${chalk.yellow.bold(partnerName)} Balance ${payOutType} payout: ${chalk.green(await web3.eth.getBalance(partnerAddress)/1e18)} ether.
        `)
    }

});