// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8 .0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Verify.sol";

contract MeetsWorld is Ownable,ERC721, ERC721Enumerable, ReentrancyGuard, VerifySignature, PaymentSplitter {

    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIds;

    uint256 public maxTotalSupply = 4888;
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

    address private builder; // 10%

    address private marketingA; // 2%

    address private marketingB; // 4%

    mapping(address => bool) public whitelist;

    mapping(address => uint256) public whitelistMinted;
    mapping(address => uint256) public publicMinted;

    uint256 listingPrice = 0.16 ether;
    uint256 whitelistPrice = 0.11 ether;

    mapping(address => uint256) public partnerBalances;

    string public ipfsGateway = "https://gateway.pinata.cloud/ipfs/";
    string public ipfsHash = "QmX49QfWRfNwot4c6k6FAP6jNXcn4ssCwjndLjNyToUyZT";

    constructor(
        address[] memory _payees,
        uint256[] memory _shares,
        address _verificationAdmin
    ) ERC721("Meetsmeta", "MM") PaymentSplitter(_payees, _shares) payable {
        verificationAdmin = _verificationAdmin;
    }

    // PUBLIC

    function mintPassesWhitelist(uint8 _toMint)
    public
    payable
    nonReentrant {
        require(_toMint <= mutipleMintingLimit, "Only 3 NFT's mint at a time.");
        require(whitelistMintingStart, "Whitelist not started yet.");
        require(whitelist[msg.sender], "Address is not whitelisted.");
        require(maxTotalSupply >= (_tokenIds.current() + _toMint), "Minting Finished");
        require(msg.value == whitelistPrice * _toMint, "Incorrect Amount.");
        require((whitelistMinted[msg.sender] + _toMint) <= maxWhitelistminting, "Whitelist minting limit reached for this address.");

        whitelistMinted[msg.sender] += _toMint;
        mintMultiple(_toMint);
    }

    function mintPassesPublic(uint8 _toMint)
    public
    payable
    nonReentrant {
        require(_toMint <= mutipleMintingLimit, "Only 3 NFT's mint at a time.");
        require(publicMintingStart, "Public minting not started yet.");
        require(maxTotalSupply >= (_tokenIds.current() + _toMint), "Minting Finished");
        require(msg.value == listingPrice * _toMint, "Incorrect Amount.");
        require((publicMinted[msg.sender] + _toMint) <= maxMintingLimit, "Minting limit reached for this address.");

        publicMinted[msg.sender] += _toMint;
        mintMultiple(_toMint);

    }

    function mintPassesVerified(MintPayload calldata _payload, bytes memory _signature)
    public
    payable
    nonReentrant {
        require(maxTotalSupply > _tokenIds.current(), "Minting Finished");
        require(msg.value == whitelistPrice * _payload._toMint, "Incorrect Amount.");
        require(verifyOwnerSignature(_payload, _signature), "Invalid Signature");
        require((whitelistMinted[msg.sender] + _payload._toMint) <= maxWhitelistminting, "Whitelist minting limit reached for this address.");

        whitelistMinted[msg.sender] += _payload._toMint;
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

    // emergency swip out
    function swipOut() public onlyOwner {
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

    /**
     * override(ERC721, ERC721Enumerable, ERC721Pausable)
     * here you're overriding _beforeTokenTransfer method of
     * three Base classes namely ERC721, ERC721Enumerable, ERC721Pausable
     * */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal
      override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * override(ERC721, ERC721Enumerable) -> here you're specifying only two base classes ERC721, ERC721Enumerable
     * */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}
