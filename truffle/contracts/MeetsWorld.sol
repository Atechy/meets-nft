// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Verify.sol";

contract MeetsWorld is Ownable, ERC721 , ReentrancyGuard , VerifySignature {

    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    Counters.Counter private _tokenIds;

    uint256 public totalSupply = 4888;
    uint256 public maxMintingLimit = 3;

    bool public whitelistMintingStart=false;
    bool public normalMintngStart=false;

    struct MintPayload {
        address to;
        uint256 nonce;
    }

    address private verificationAdmin;

    address payable builder; // 10%

    address payable marketingA; // 2%

    address payable marketingB; // 4%

    mapping(address => bool) public whitelist;

    uint256 listingPrice = 0.16 ether;
    uint256 whitelistPrice = 0.11 ether;

    mapping(address => uint256) public partnerBalances;

    string public ipfsGateway = "https://gateway.pinata.cloud/ipfs/";
    string public ipfsHash = "QmX49QfWRfNwot4c6k6FAP6jNXcn4ssCwjndLjNyToUyZT";

    constructor(
        address _builder,
        address _marketingA,
        address _marketingB,
        address _verificationAdmin
    ) public ERC721("Meetsmeta", "MM") {
        builder = payable(_builder);
        marketingA = payable(_marketingA);
        marketingB = payable(_marketingB);
        partnerBalances[msg.sender] = 0 ether;
        partnerBalances[_builder] = 0 ether;
        partnerBalances[_marketingA] = 0 ether;
        partnerBalances[_marketingB] = 0 ether;
        verificationAdmin=_verificationAdmin;
    }

    // PUBLIC

    function mintPasses()
        public
        payable
        nonReentrant
        returns (uint256)
    {

        require(totalSupply > _tokenIds.current(), "Minting Finished");
        if (whitelist[msg.sender] == true && balanceOf(msg.sender) < maxMintingLimit && whitelistMintingStart) {
            require(msg.value == whitelistPrice, "Incorrect Amount.");
        } else {
            require(normalMintngStart,"Minting Stoped.");
            require(msg.value == listingPrice, "Incorrect Amount.");
        }

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        if (whitelist[msg.sender] == true) {
            partnerBalances[owner()] = partnerBalances[owner()].add(0.0924 ether);// 84%
            partnerBalances[builder] = partnerBalances[builder].add(0.011 ether);// 10%
            partnerBalances[marketingA] = partnerBalances[marketingA].add(0.0022 ether);// 2%
            partnerBalances[marketingB] = partnerBalances[marketingB].add(0.0044 ether);// 4%
        } else {
            partnerBalances[owner()] = partnerBalances[owner()].add(0.1344 ether);// 84%
            partnerBalances[builder] = partnerBalances[builder].add(0.016 ether);// 10%
            partnerBalances[marketingA] = partnerBalances[marketingA].add(0.0032 ether);// 2%
            partnerBalances[marketingB] = partnerBalances[marketingB].add(0.0064  ether);// 4%
        }

        _safeMint(msg.sender, newItemId);
        return newItemId;
    }

    function mintPassesVerified(MintPayload calldata _payload, bytes memory _signature)
        public
        payable
        nonReentrant
        returns (uint256)
    {

        require(totalSupply > _tokenIds.current(), "Minting Finished");
        require(msg.value == whitelistPrice, "Incorrect Amount.");
        require(verifyOwnerSignature(_payload, _signature), "Invalid Signature");

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        if (whitelist[msg.sender] == true) {
            partnerBalances[owner()] = partnerBalances[owner()].add(0.0924 ether);// 84%
            partnerBalances[builder] = partnerBalances[builder].add(0.011 ether);// 10%
            partnerBalances[marketingA] = partnerBalances[marketingA].add(0.0022 ether);// 2%
            partnerBalances[marketingB] = partnerBalances[marketingB].add(0.0044 ether);// 4%
        } else {
            partnerBalances[owner()] = partnerBalances[owner()].add(0.1344 ether);// 84%
            partnerBalances[builder] = partnerBalances[builder].add(0.016 ether);// 10%
            partnerBalances[marketingA] = partnerBalances[marketingA].add(0.0032 ether);// 2%
            partnerBalances[marketingB] = partnerBalances[marketingB].add(0.0064  ether);// 4%
        }

        _safeMint(msg.sender, newItemId);
        return newItemId;
    }

    modifier checksBeforeWithdraw(address _partner){
        require(partnerBalances[_partner] > 0,"Nothing to withdraw");
        _;
    }

    function requestPayout() public checksBeforeWithdraw(msg.sender) nonReentrant {
        payable(msg.sender).transfer(partnerBalances[msg.sender]);
        partnerBalances[msg.sender] = 0;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ipfsGateway,ipfsHash,'/',tokenId.toString(),'.json'));
    }

    // PUBLIC ONLY OWNER

    function setWhitelistMinting(bool _whitelistMintingStart) external onlyOwner{
         whitelistMintingStart=_whitelistMintingStart;
    }

    function setNormalMintng(bool _normalMintngStart) external onlyOwner{
        normalMintngStart=_normalMintngStart;
    }

    function whitelistAddress(address[] calldata addrs) public onlyOwner {
        for (uint i = 0; i < addrs.length; i++) {
            whitelist[addrs[i]] = true;
        }
    }

    function setVerificationAdmin (address _verificationAdmin) public onlyOwner {
        verificationAdmin = _verificationAdmin;
    }

    function setIpfsgateway (string memory _ipfsgateway) public onlyOwner {
        ipfsGateway = _ipfsgateway;
    }

    function setIpfshash (string memory _ipfshash) public onlyOwner {
        ipfsHash = _ipfshash;
    }


    function swipOut() public onlyOwner {
        // transfer to all accounts the balances and the reset to the owner
        if(partnerBalances[owner()] > 0 && address(this).balance > partnerBalances[owner()]){
            payable(owner()).transfer(partnerBalances[owner()]);
            partnerBalances[owner()] = 0;
        }
        if(partnerBalances[builder] > 0 && address(this).balance > partnerBalances[builder]){
            payable(builder).transfer(partnerBalances[builder]);
            partnerBalances[builder] = 0;
        }
        if(partnerBalances[marketingA] > 0 && address(this).balance > partnerBalances[marketingA]){
           payable(marketingA).transfer(partnerBalances[marketingA]);
           partnerBalances[marketingA] = 0;
        }
        if(partnerBalances[marketingB] > 0 && address(this).balance > partnerBalances[marketingB]){
           payable(marketingB).transfer(partnerBalances[marketingB]);
           partnerBalances[marketingB] = 0;
        }
        // transfering remaining balance to the owner
        if(address(this).balance > 0){
            payable(owner()).transfer(address(this).balance);
        }
    }

    // INTERNAL

    function verifyOwnerSignature(MintPayload calldata _payload, bytes memory _signature) public view returns(bool) {

          bytes32 ethSignedHash = getEthSignedMessageHash(getMessageHash(_payload.nonce.toString(),_payload.to));
          return recoverSigner(ethSignedHash,_signature) == verificationAdmin;

    }

}
