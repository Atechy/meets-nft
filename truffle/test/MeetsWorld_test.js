const MeetsWorld = artifacts.require('./MeetsWorld.sol');
require('dotenv').config();
const chalk = require('chalk');
const log = console.log;

// const BUILDER = process.env.BUILDER
// const MARKETINGA = process.env.MARKETINGA
// const MARKETINGB = process.env.MARKETINGB
// const VerificationAdmin = "0x627306090abaB3A6e1400e9345bC60c78a8BEf57"

contract('Test for MeetsWorld', (accounts) => {

    // fetch accounts on different index
    let [OWNER, Alan, Bob, Charlie, Dave, Elon, BUILDER, MARKETINGA, MARKETINGB, VerificationAdmin] = accounts;
    let MeetsWorldContract;

    beforeEach(async () => {
        log(`
            Contract deployed by ${chalk.yellow.bold('OWNER')}(${chalk.green(OWNER)})          
            ${chalk.yellow.bold('BUILDER')} Address:-${chalk.green(BUILDER)}             
            ${chalk.yellow.bold('MARKETINGA')} Address:-${chalk.green(MARKETINGA)}           
            ${chalk.yellow.bold('MARKETINGB')} Address:-${chalk.green(MARKETINGB)}
            ${chalk.yellow.bold('VerificationAdmin')} Address:-${chalk.green(VerificationAdmin)}`)
        
        const listingPrice = 160000000000000000;
        const whitelistPrice = 110000000000000000;

        meetsworld = await MeetsWorld.new(BUILDER, MARKETINGA, MARKETINGB, VerificationAdmin,);
    });

    xit(`Should mint at normal listing price after validating all checks`, async () => {
        log(`
            Using address of Alan which is ${chalk.green(Alan)} to mint public passes.
            
            LISTING PRICE IS ${chalk.yellow('0.16 ether')}`) 
        
        log(`
            This transaction should fail as NFT's to mint are greater than 3`)
        try {
            await mintPassesPublic(4, Alan);
        } catch(e){
            assert(e.message.includes(`Only 3 NFT's mint at a time`));
            log(`
                ${chalk.red(`ERROR: Only 3 NFT's mint at a time`)}`)
        }
        
        log(`
            This transaction should fail as public minting has not started yet.`)
        try {
            await mintPassesPublic(1, Alan);
        } catch(e){
            assert(e.message.includes(`Public minting not started yet`));
            log(`
                ${chalk.red(`ERROR: Public minting not started yet`)}`)
        }
        
        await setPublicMinting(true)
        
        log(`
            Sending same transaction after setting public minting true`)
        
        await mintPassesPublic(1, Alan);
        
        log(`${chalk.green(`
            Mint successful.`)}`);
        
        await checkNumberOfTokensPublicMintedPerAddress(Alan);
        
        log(`
            This transaction should fail as the minting price is incorrect.`)
        try {
            await meetsworld.mintPassesPublic(1, {from: Alan, value: 100});
        } catch(e){
            assert(e.message.includes(`Incorrect Amount`));
            log(`
                ${chalk.red(`ERROR: Incorrect Amount`)}`)
        }

        log(`
            Minting 2 NFT's after changing the value to the correct listing price`)
        
        await mintPassesPublic(2, Alan);

        log(`${chalk.green(`
            Mint successful.`)}`);
        
        await checkNumberOfTokensPublicMintedPerAddress(Alan);
        
        log(`
            This transaction should fail as the minting limit for this address has been reached.`)
        try {
            await mintPassesPublic(1, Alan);
        } catch(e){
            assert(e.message.includes(`Minting limit reached for this address`));
            log(`
                ${chalk.red(`ERROR: Minting limit reached for this address`)}`)
        }
        
        await showBalancesInEther(Alan);

    })

    xit(`Should mint for whitelist addresses at whitelist price while validating all checks`, async () => {
        log(`
            Using address of Bob which is ${chalk.green(Bob)} to mint public passes.
        
            WHITELIST PRICE IS ${chalk.yellow('0.11 ether')}`)
        
        log(`
            This transaction should fail as NFT's to mint are greater than 3`)
        try {
            await mintPassesWhitelist(4, Bob);
        } catch(e){
            assert(e.message.includes(`Only 3 NFT's mint at a time`));
            log(`
                ${chalk.red(`ERROR: Only 3 NFT's mint at a time`)}`)
        }
        
        log(`
            This transaction should fail as whitelist minting has not started yet.`)
        try {
            await mintPassesWhitelist(1, Bob);
        } catch(e){
            assert(e.message.includes(`Whitelist not started yet`));
            log(`
                 ${chalk.red(`ERROR: Whitelist not started yet`)}`)
        }
        
        await meetsworld.setWhitelistMinting(true)
        
        log(`
            Sending same transaction after setting whitelist minting true but xit should still fail as address of Bob which is ${chalk.green(Bob)} is not whitelisted`)
        try {
            await mintPassesWhitelist(1, Bob);
        } catch(e){
            assert(e.message.includes(`Address is not whitelisted`));
            log(`
                 ${chalk.red(`ERROR: Address is not whitelisted`)}`)
        }

        log(`
            Sending same transaction after setting whitelist minting true and adding Bob to whitelist and also adding Charlie to whitelist to check multiple addresses as input to add to whitelist.`)
        await meetsworld.whitelistAddress([Bob, Charlie]);
        log(`
            Addresses submitted to whitelist are ${chalk.green(Bob)} and ${chalk.green(Charlie)}
            
            Checking the status of the addresses in whitelist`)
        await isWhitelisted(Bob)
        await isWhitelisted(Charlie)
        await isWhitelisted(Dave)
        
        await mintPassesWhitelist(1, Bob);

        log(`${chalk.green(`
            Mint successful.`)}`);
        
        await checkNumberOfTokensWhitelistMintedPerAddress(Bob);

        log(`
            This transaction should fail as the minting price is incorrect.`)
        try {
            await meetsworld.mintPassesWhitelist(1, {from: Bob, value: 100});
        } catch(e){
            assert(e.message.includes(`Incorrect Amount`));
            log(`
                ${chalk.red(`ERROR: Incorrect Amount`)}`)
        }

        log(`
            Minting 2 NFT's after changing the value to the correct whitelist minting price`)
        
        await mintPassesWhitelist(2, Bob);

        log(`
            ${chalk.green(`Mint successful.`)}`);
        
        await checkNumberOfTokensWhitelistMintedPerAddress(Bob);

        log(`
            This transaction should fail as the whitelist minting limit for this address has been reached.`)
        try {
            await mintPassesWhitelist(1, Bob);
        } catch(e){
            assert(e.message.includes(`Whitelist minting limit reached for this address`));
            log(`
                ${chalk.red(`ERROR: Whitelist minting limit reached for this address`)}`)
        }

        await showBalancesInEther(Bob);
    
    })

    xit(`Should mint passes after verifying the signature and validating all the checks`, async () => {
        await mintPassesVerified();
    })

    xit(`Should fulfill the request of payout and transfer the ether to the partners when they call the requestPayout function`, async () => {
        log(`
            Minting NFT's from 5 different accounts (Alan, Bob, Charlie, Dave, Elon) so that there will be balances in partners addresses.`);
        await setPublicMinting(true)
        await mintPassesPublic(3, Alan, {from : Alan})
        await mintPassesPublic(3, Bob, {from : Bob})
        await mintPassesPublic(3, Charlie, {from : Charlie})
        await mintPassesPublic(3, Dave, {from : Dave})
        await mintPassesPublic(3, Elon, {from : Elon})
        
        owner = await meetsworld.partnerBalances.call(OWNER);
        builder = await meetsworld.partnerBalances.call(BUILDER);
        marketingA = await meetsworld.partnerBalances.call(MARKETINGA);
        marketingB = await meetsworld.partnerBalances.call(MARKETINGB);

        log(`
            Balances of all the partners after 15 NFT minting are:`)

        log(`
            COST OF MINTING 15 NORMAL PUBLIC NFT'S IS 2.4 ETHER.
            
            84% OF 2.4 IS 2.016 ETHER

            10% OF 2.4 IS 0.24 ETHER

            2% OF 2.4 IS 0.048 ETHER

            4% OF 2.4 IS 0.096 ETHER
        
            Balance of OWNER after distribution is ${chalk.green(web3.utils.fromWei(owner))}
            
            Balance of BUILDER after distribution is ${chalk.green(web3.utils.fromWei(builder))}
            
            Balance of MARKETINGA after distribution is ${chalk.green(web3.utils.fromWei(marketingA))}
            
            Balance of MARKETINGB after distribution is ${chalk.green(web3.utils.fromWei(marketingB))}
            `)
        
        ownerBefore = await meetsworld.partnerBalances.call(OWNER);
        builderBefore = await meetsworld.partnerBalances.call(BUILDER);
        marketingABefore = await meetsworld.partnerBalances.call(MARKETINGA);
        marketingBBefore = await meetsworld.partnerBalances.call(MARKETINGB);

        await meetsworld.requestPayout({from : OWNER});
        
        ownerAfter = await meetsworld.partnerBalances.call(OWNER);

        log(`
            OWNER REQUESTED PAYOUT

            Balance of OWNER before requesting Payout is ${chalk.yellow(web3.utils.fromWei(ownerBefore))}
            Balance of OWNER after requesting Payout is ${chalk.yellow(web3.utils.fromWei(ownerAfter))}
            `)

        await meetsworld.requestPayout({from : BUILDER});
        builderAfter = await meetsworld.partnerBalances.call(BUILDER);
        
        log(`
            BUILDER REQUESTED PAYOUT
            
            Balance of BUILDER before requesting Payout is ${chalk.yellow(web3.utils.fromWei(builderBefore))}
            Balance of BUILDER after requesting Payout is ${chalk.yellow(web3.utils.fromWei(builderAfter))}
            `)

        await meetsworld.requestPayout({from : MARKETINGA});
        marketingAAfter = await meetsworld.partnerBalances.call(MARKETINGA);

        log(`
            MARKETING_A REQUESTED PAYOUT
            
            Balance of MARKETING_A before requesting Payout is ${chalk.yellow(web3.utils.fromWei(marketingABefore))}
            Balance of MARKETING_A after requesting Payout is ${chalk.yellow(web3.utils.fromWei(marketingAAfter))}
            `)

        await meetsworld.requestPayout({from : MARKETINGB});
        marketingBAfter = await meetsworld.partnerBalances.call(MARKETINGB);

        log(`
            MARKETING_B REQUESTED PAYOUT
            
            Balance of MARKETING_B before requesting Payout is ${chalk.yellow(web3.utils.fromWei(marketingBBefore))}
            Balance of MARKETING_B after requesting Payout is ${chalk.yellow(web3.utils.fromWei(marketingAAfter))}
            `)

        log(`
            Request of Payout from any partner should fail when their balance is 0
            
            Requesting from OWNER when balance is 0`)
        try {
            await meetsworld.requestPayout({from : OWNER});
        } catch (e) {
            assert(e.message.includes(`Nothing to withdraw`))
            log(`
                ${chalk.red(`ERROR: Nothing to withdraw.`)}`)
        }

        log(`  
            Requesting from BUILDER when balance is 0`)
        try {
            await meetsworld.requestPayout({from : BUILDER});
        } catch (e) {
            assert(e.message.includes(`Nothing to withdraw`))
            log(`
                ${chalk.red(`ERROR: Nothing to withdraw.`)}`)
        }

        log(`
            Requesting from MARKETINGA when balance is 0`)
        try {
            await meetsworld.requestPayout({from : MARKETINGA});
        } catch (e) {
            assert(e.message.includes(`Nothing to withdraw`))
            log(`
                ${chalk.red(`ERROR: Nothing to withdraw.`)}`)
        }

        log(`
            Requesting from MARKETINGB when balance is 0`)
        try {
            await meetsworld.requestPayout({from : MARKETINGB});
        } catch (e) {
            assert(e.message.includes(`Nothing to withdraw`))
            log(`
                ${chalk.red(`ERROR: Nothing to withdraw.`)}`)
        }

    })

    it(`Should transfer all the balances to relevant partner when owner calls swipeout function`, async () => {
        log(`
            Setting maxMintingLimit to 100 in the SMART CONTRACT for this test case`)
        
        log(`
            Minting NFT's from 5 different accounts (Alan, Bob, Charlie, Dave, Elon) so that there will be balances in partners addresses.`);
        await setPublicMinting(true)
        await mintPassesPublic(3, Alan, {from : Alan})
        await mintPassesPublic(3, Bob, {from : Bob})
        await mintPassesPublic(3, Charlie, {from : Charlie})
        await mintPassesPublic(3, Dave, {from : Dave})
        await mintPassesPublic(3, Elon, {from : Elon})
        
        owner = await meetsworld.partnerBalances.call(OWNER);
        builder = await meetsworld.partnerBalances.call(BUILDER);
        marketingA = await meetsworld.partnerBalances.call(MARKETINGA);
        marketingB = await meetsworld.partnerBalances.call(MARKETINGB);

        log(`
            Balances of all the partners after 15 NFT minting are:`)

        log(`
            COST OF MINTING 15 NORMAL PUBLIC NFT'S IS 2.4 ETHER.
            
            84% OF 2.4 IS 2.016 ETHER

            10% OF 2.4 IS 0.24 ETHER

            2% OF 2.4 IS 0.048 ETHER

            4% OF 2.4 IS 0.096 ETHER
        
            Balance of OWNER after distribution is ${chalk.green(web3.utils.fromWei(owner))}
            
            Balance of BUILDER after distribution is ${chalk.green(web3.utils.fromWei(builder))}
            
            Balance of MARKETINGA after distribution is ${chalk.green(web3.utils.fromWei(marketingA))}
            
            Balance of MARKETINGB after distribution is ${chalk.green(web3.utils.fromWei(marketingB))}
            `)
        
        ownerBefore = await meetsworld.partnerBalances.call(OWNER);
        builderBefore = await meetsworld.partnerBalances.call(BUILDER);
        marketingABefore = await meetsworld.partnerBalances.call(MARKETINGA);
        marketingBBefore = await meetsworld.partnerBalances.call(MARKETINGB);

        await meetsworld.swipOut({from : OWNER});

        ownerAfter = await meetsworld.partnerBalances.call(OWNER);
        builderAfter = await meetsworld.partnerBalances.call(BUILDER);
        marketingAAfter = await meetsworld.partnerBalances.call(MARKETINGA);
        marketingBAfter = await meetsworld.partnerBalances.call(MARKETINGB);

        log(`
            OWNER CALLS SWIPEOUT FOR THE FIRST TIME

            Balance of OWNER before calling SWIPEOUT is ${chalk.yellow(web3.utils.fromWei(ownerBefore))}
            Balance of OWNER after calling SWIPEOUT is ${chalk.yellow(web3.utils.fromWei(ownerAfter))}

            Balance of BUILDER before calling SWIPEOUT is ${chalk.yellow(web3.utils.fromWei(builderBefore))}
            Balance of BUILDER after calling SWIPEOUT is ${chalk.yellow(web3.utils.fromWei(builderAfter))}

            Balance of MARKETINGA before calling SWIPEOUT is ${chalk.yellow(web3.utils.fromWei(marketingABefore))}
            Balance of MARKETINGA after calling SWIPEOUT is ${chalk.yellow(web3.utils.fromWei(marketingAAfter))}

            Balance of MARKETINGA before calling SWIPEOUT is ${chalk.yellow(web3.utils.fromWei(marketingBBefore))}
            Balance of MARKETINGA after calling SWIPEOUT is ${chalk.yellow(web3.utils.fromWei(marketingBAfter))}
            `)  

        log(`
            Minting NFT's from 5 different accounts (Alan, Bob, Charlie, Dave, Elon) for the second time`);
        await mintPassesPublic(3, Alan, {from : Alan})
        await mintPassesPublic(3, Bob, {from : Bob})
        await mintPassesPublic(3, Charlie, {from : Charlie})
        await mintPassesPublic(3, Dave, {from : Dave})
        await mintPassesPublic(3, Elon, {from : Elon})

        ownerBefore2 = await meetsworld.partnerBalances.call(OWNER);
        builderBefore2 = await meetsworld.partnerBalances.call(BUILDER);
        marketingABefore2 = await meetsworld.partnerBalances.call(MARKETINGA);
        marketingBBefore2 = await meetsworld.partnerBalances.call(MARKETINGB);

        await meetsworld.swipOut({from : OWNER});

        ownerAfter2 = await meetsworld.partnerBalances.call(OWNER);
        builderAfter2 = await meetsworld.partnerBalances.call(BUILDER);
        marketingAAfter2 = await meetsworld.partnerBalances.call(MARKETINGA);
        marketingBAfter2 = await meetsworld.partnerBalances.call(MARKETINGB);

        log(`
            OWNER CALLS SWIPEOUT FOR THE SECOND TIME

            Balance of OWNER before calling SWIPEOUT is ${chalk.yellow(web3.utils.fromWei(ownerBefore2))}
            Balance of OWNER after calling SWIPEOUT is ${chalk.yellow(web3.utils.fromWei(ownerAfter2))}

            Balance of BUILDER before calling SWIPEOUT is ${chalk.yellow(web3.utils.fromWei(builderBefore2))}
            Balance of BUILDER after calling SWIPEOUT is ${chalk.yellow(web3.utils.fromWei(builderAfter2))}

            Balance of MARKETINGA before calling SWIPEOUT is ${chalk.yellow(web3.utils.fromWei(marketingABefore2))}
            Balance of MARKETINGA after calling SWIPEOUT is ${chalk.yellow(web3.utils.fromWei(marketingAAfter2))}

            Balance of MARKETINGA before calling SWIPEOUT is ${chalk.yellow(web3.utils.fromWei(marketingBBefore2))}
            Balance of MARKETINGA after calling SWIPEOUT is ${chalk.yellow(web3.utils.fromWei(marketingBAfter2))}
            `)

        log(`
            Minting NFT's from 5 different accounts (Alan, Bob, Charlie, Dave, Elon) for the third time two times for a total of 30 NFT's`);
        await mintPassesPublic(3, Alan, {from : Alan})
        await mintPassesPublic(3, Alan, {from : Alan})
        await mintPassesPublic(3, Bob, {from : Bob})
        await mintPassesPublic(3, Bob, {from : Bob})
        await mintPassesPublic(3, Charlie, {from : Charlie})
        await mintPassesPublic(3, Charlie, {from : Charlie})
        await mintPassesPublic(3, Dave, {from : Dave})
        await mintPassesPublic(3, Dave, {from : Dave})
        await mintPassesPublic(3, Elon, {from : Elon})
        await mintPassesPublic(3, Elon, {from : Elon})

        ownerBefore3 = await meetsworld.partnerBalances.call(OWNER);
        builderBefore3 = await meetsworld.partnerBalances.call(BUILDER);
        marketingABefore3 = await meetsworld.partnerBalances.call(MARKETINGA);
        marketingBBefore3 = await meetsworld.partnerBalances.call(MARKETINGB);

        await meetsworld.swipOut({from : OWNER});

        ownerAfter3 = await meetsworld.partnerBalances.call(OWNER);
        builderAfter3 = await meetsworld.partnerBalances.call(BUILDER);
        marketingAAfter3 = await meetsworld.partnerBalances.call(MARKETINGA);
        marketingBAfter3 = await meetsworld.partnerBalances.call(MARKETINGB);

        log(`
            OWNER CALLS SWIPEOUT FOR THE THIRD TIME

            Balance of OWNER before calling SWIPEOUT is ${chalk.yellow(web3.utils.fromWei(ownerBefore3))}
            Balance of OWNER after calling SWIPEOUT is ${chalk.yellow(web3.utils.fromWei(ownerAfter3))}

            Balance of BUILDER before calling SWIPEOUT is ${chalk.yellow(web3.utils.fromWei(builderBefore3))}
            Balance of BUILDER after calling SWIPEOUT is ${chalk.yellow(web3.utils.fromWei(builderAfter3))}

            Balance of MARKETINGA before calling SWIPEOUT is ${chalk.yellow(web3.utils.fromWei(marketingABefore3))}
            Balance of MARKETINGA after calling SWIPEOUT is ${chalk.yellow(web3.utils.fromWei(marketingAAfter3))}

            Balance of MARKETINGA before calling SWIPEOUT is ${chalk.yellow(web3.utils.fromWei(marketingBBefore3))}
            Balance of MARKETINGA after calling SWIPEOUT is ${chalk.yellow(web3.utils.fromWei(marketingBAfter3))}
            `)

    })

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                                          FUNCTIONS
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    async function mintPassesVerified() {
        var signer = VerificationAdmin
        const whitelistPrice = 110000000000000000;
        var _toAddress = Dave;
        var hash = await meetsworld.getMessageHash('1', _toAddress);
        log(`
            Hash is ${chalk.cyan(hash)}`);
        var getEthSignedMessageHash = await meetsworld.getEthSignedMessageHash(hash);
        log(`
            Ethereum Signed Message Hash is ${chalk.cyan(getEthSignedMessageHash)}`);
        var signature = await web3.eth.sign(hash, VerificationAdmin);
        //signature = signature.substr(0, 130) + (signature.substr(130) == "00" ? "1b" : "1c"); // v: 0,1 => 27,28
        log(`
            Signature is ${chalk.cyan(signature)}`);
        var recoverSigner = await meetsworld.recoverSigner(getEthSignedMessageHash, signature);
        log(`
            Recovering Signer
            Address of admin is ${chalk.cyan(signer)}
            Signer is ${chalk.cyan(recoverSigner)}
            To address is ${chalk.cyan(_toAddress)}
            
            Minting a NFT for ${chalk.green(Dave)} with nonce value '1' for the first time`);
        await meetsworld.mintPassesVerified([_toAddress, '1', 1], signature , {from: _toAddress, value: whitelistPrice});
        log(`${chalk.green(`
            Mint successful.`)}`);
        log(`
            Minting a NFT for ${chalk.green(Dave)} with nonce value '1' for the second time with incorrect price should throw an error of incorrect mint price.`);
        try {
            await meetsworld.mintPassesVerified([_toAddress, '1', 1], signature , {from: _toAddress, value: 100000000000000000});
        } catch(e) {
            assert(e.message.includes(`Incorrect Amount`));
            log(`
                ${chalk.red(`ERROR: Incorrect Amount.`)}`)
        }
        log(`
            Minting a NFT for ${chalk.green(Dave)} with nonce value '1' for the second time with correct price.`);
        await meetsworld.mintPassesVerified([_toAddress, '1', 1], signature , {from: _toAddress, value: whitelistPrice});
        log(`${chalk.green(`
            Mint successful.`)}`);
        log(`
            Minting a NFT for ${chalk.green(Dave)} with nonce value '2' for the third time should fail because we pass invalid signature`);
        try {
            await meetsworld.mintPassesVerified([_toAddress, 2, 1], signature , {from: _toAddress, value: whitelistPrice});
        } catch(e){
            assert(e.message.includes(`Invalid Signature`));
            log(`
                ${chalk.red(`ERROR: Invalid Signature.`)}`)
        }
        log(`
            Minting a NFT for ${chalk.green(Dave)} with nonce value '1' for the third time with valid signature`);
        await meetsworld.mintPassesVerified([_toAddress, '1', 1], signature , {from: _toAddress, value: whitelistPrice});
        log(`${chalk.green(`
            Mint successful.`)}`);
        log(`
            Minting a NFT for ${chalk.green(Dave)} with nonce value '1' for the fourth time should throw an error as current addressMintingLimit is 3.`);
        try {
            await meetsworld.mintPassesVerified([_toAddress, '1', 1], signature , {from: _toAddress, value: whitelistPrice});
        } catch(e){
            assert(e.message.includes(`Whitelist minting limit reached for this address`));
            log(`
                ${chalk.red(`ERROR: Whitelist minting limit reached for this address.`)}`)
        }
    }

    async function mintPassesWhitelist(_toMint, address) {
        const whitelistPrice = 110000000000000000;
        await meetsworld.mintPassesWhitelist(_toMint, {from: address, value: whitelistPrice * _toMint}); 
    }

    async function mintPassesPublic(_toMint, address) {
        const listingPrice = 160000000000000000;
        await meetsworld.mintPassesPublic(_toMint, {from: address, value: listingPrice * _toMint});        
    }

    async function setPublicMinting(_parm){
        if(_parm){
            await meetsworld.setPublicMinting(true,{from: OWNER})
        }else{
            await meetsworld.setPublicMinting(true,{from: OWNER})
        } 
    }

    async function showBalancesInEther(address) {
        let balance = await web3.eth.getBalance(address);
        log(`
            Balance of ${chalk.green(address)} in ether is ${chalk.green(web3.utils.fromWei(balance))}.`)
    }

    async function checkNumberOfTokensPublicMintedPerAddress (address) {
        number = await meetsworld.publicMinted.call(address);
        log(`
            Number of NFT's minted for address ${chalk.green(address)} is ${chalk.green(number)}`)

    }
    
    async function checkNumberOfTokensWhitelistMintedPerAddress (address) {
        number = await meetsworld.whitelistMinted.call(address);
        log(`
            Number of NFT's minted for address ${chalk.green(address)} is ${chalk.green(number)}`)

    }

    async function isWhitelisted(address) {
        let isWhitelisted = await meetsworld.whitelist.call(address);
        if (isWhitelisted == false) {
        log(`
            ${chalk.green(address)} address in whitelist = ${chalk.red(isWhitelisted)}`);
        } else {
        log(`
            ${chalk.green(address)} address in whitelist = ${chalk.green(isWhitelisted)}`);
        }  
    }

})
