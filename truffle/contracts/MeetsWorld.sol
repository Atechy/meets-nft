// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8 .0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Verify.sol";

contract MeetsWorld is Ownable, ERC721, ReentrancyGuard, VerifySignature {

    using Countersn for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIds;

    uint256 public totalSupply = 4888;
    uint256 public maxMintingLimit = 3;
    uint256 public maxWhitelistminting = 3;
    uint256 public mutipleMintingLimit = 3;

    bool public whitelistMintingStart = false;
    bool public publicMintingStart = false;

    struct MintPayload {
        address to;
        uint256 nonce;
        uint8 _toMint;
    }

    address private verificationAdmin;

    address payable builder; // 10%

    address payable marketingA; // 2%

    address payable marketingB; // 4%

    mapping(address => bool) public whitelist;

    mapping(address => uint256) public whitelistMinted;
    mapping(address => uint256) public publicMinted;

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
        verificationAdmin = _verificationAdmin;
    }

    // PUBLIC

    function mintPassesWhitelist(uint8 _toMint)
    public
    payable
    nonReentrant() {
        require(_toMint <= mutipleMintingLimit, "Only 3 NFT's mint at a time.");
        require(whitelistMintingStart, "Whitelist not started yet.");
        require(whitelist[msg.sender], "Address is not whitelisted.");
        require(totalSupply >= (_tokenIds.current() + _toMint), "Minting Finished");
        require(msg.value == whitelistPrice * _toMint, "Incorrect Amount.");
        require((whitelistMinted[msg.sender] + _toMint) <= maxWhitelistminting, "Whitelist minting limit reached for this address.");

        whitelistMinted[msg.sender] += _toMint;
        distributeEth(true, _toMint);
        mintMultiple(_toMint);
    }

    function mintPassesPublic(uint8 _toMint)
    public
    payable
    nonReentrant() {
        require(_toMint <= mutipleMintingLimit, "Only 3 NFT's mint at a time.");
        require(publicMintingStart, "Public minting not started yet.");
        require(totalSupply >= (_tokenIds.current() + _toMint), "Minting Finished");
        require(msg.value == listingPrice * _toMint, "Incorrect Amount.");
        require((publicMinted[msg.sender] + _toMint) <= maxMintingLimit, "Minting limit reached for this address.");

        publicMinted[msg.sender] += _toMint;
        distributeEth(false, _toMint);
        mintMultiple(_toMint);

    }

    function mintPassesVerified(MintPayload calldata _payload, bytes memory _signature)
    public
    payable
    nonReentrant() {
        require(totalSupply > _tokenIds.current(), "Minting Finished");
        require(msg.value == whitelistPrice * _payload._toMint, "Incorrect Amount.");
        require(verifyOwnerSignature(_payload, _signature), "Invalid Signature");
        require((whitelistMinted[msg.sender] + _payload._toMint) <= maxWhitelistminting, "Whitelist minting limit reached for this address.");
        
        whitelistMinted[msg.sender] += _payload._toMint;
        distributeEth(true, _payload._toMint);
        mintMultiple(_payload._toMint);
    }

    modifier checksBeforeWithdraw(address _partner) {
        require(partnerBalances[_partner] > 0, "Nothing to withdraw");
        _;
    }

    function requestPayout() public checksBeforeWithdraw(msg.sender) nonReentrant {
        payable(msg.sender).transfer(partnerBalances[msg.sender]);
        partnerBalances[msg.sender] = 0;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns(string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(ipfsGateway, ipfsHash, '/', _tokenId.toString(), '.json'));

    }

    // PUBLIC ONLY OWNER

    function setWhitelistMinting(bool _whitelistMintingStart) external onlyOwner {
        whitelistMintingStart = _whitelistMintingStart;
    }

    function setPublicMinting(bool _publicMintingStart) external onlyOwner {
        publicMintingStart = _publicMintingStart;
    }

    function whitelistAddress(address[] calldata addrs) public onlyOwner {
        for (uint i = 0; i < addrs.length; i++) {
            whitelist[addrs[i]] = true;
        }
    }

    function setVerificationAdmin(address _verificationAdmin) public onlyOwner {
        verificationAdmin = _verificationAdmin;
    }

    function setIpfsgateway(string memory _ipfsgateway) public onlyOwner {
        ipfsGateway = _ipfsgateway;
    }

    function setIpfshash(string memory _ipfshash) public onlyOwner {
        ipfsHash = _ipfshash;
    }


    function swipOut() public onlyOwner {
        // transfer to all accounts the balances and the reset to the owner
        if (partnerBalances[owner()] > 0 && address(this).balance > partnerBalances[owner()]) {
            payable(owner()).transfer(partnerBalances[owner()]);
            partnerBalances[owner()] = 0;
        }
        if (partnerBalances[builder] > 0 && address(this).balance > partnerBalances[builder]) {
            payable(builder).transfer(partnerBalances[builder]);
            partnerBalances[builder] = 0;
        }
        if (partnerBalances[marketingA] > 0 && address(this).balance > partnerBalances[marketingA]) {
            payable(marketingA).transfer(partnerBalances[marketingA]);
            partnerBalances[marketingA] = 0;
        }
        if (partnerBalances[marketingB] > 0 && address(this).balance > partnerBalances[marketingB]) {
            payable(marketingB).transfer(partnerBalances[marketingB]);
            partnerBalances[marketingB] = 0;
        }
        // transfering remaining balance to the owner
        if (address(this).balance > 0) {
            payable(owner()).transfer(address(this).balance);
        }


    }

    // INTERNAL

    function verifyOwnerSignature(MintPayload calldata _payload, bytes memory _signature) internal view returns(bool) {

        bytes32 ethSignedHash = getEthSignedMessageHash(getMessageHash(_payload.nonce.toString(), _payload.to));
        return recoverSigner(ethSignedHash, _signature) == verificationAdmin;

    }

    function mintMultiple(uint8 _toMint) internal {

        uint256 newItemId;
        for (uint8 i = 0; i < _toMint; i++) {

            _tokenIds.increment();
            newItemId = _tokenIds.current();
            _safeMint(msg.sender, newItemId);

        }
    }


    function distributeEth(bool _isWhitelist, uint8 _toMint) internal {

        if (_isWhitelist) {
            partnerBalances[owner()] += 0.0924 ether * _toMint; // 84%
            partnerBalances[builder] += 0.011 ether * _toMint; // 10%
            partnerBalances[marketingA] += 0.0022 ether * _toMint; // 2%
            partnerBalances[marketingB] += 0.0044 ether * _toMint; // 4%
        } else {
            partnerBalances[owner()] += 0.1344 ether * _toMint; // 84%
            partnerBalances[builder] += 0.016 ether * _toMint; // 10%
            partnerBalances[marketingA] += 0.0032 ether * _toMint; // 2%
            partnerBalances[marketingB] += 0.0064 ether * _toMint; // 4%
        }

    }


}