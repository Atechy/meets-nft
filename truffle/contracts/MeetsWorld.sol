// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MeetsWorld is Ownable, ERC721 {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIds;

    Counters.Counter private Basic;

    Counters.Counter private Normal;

    Counters.Counter private Rare;

    Counters.Counter private Epic;

    Counters.Counter private Exclusive;

    uint256 public BasicSupply = 6000;
    uint256 public NormalSupply = 2000;
    uint256 public RareSupply = 1500;
    uint256 public EpicSupply = 400;
    uint256 public ExclusiveSupply = 100;

    uint256 public totalSupply = 10000;

    using Strings for uint256;

    struct assignedCategory {
        address addr; // address of the owner
        uint256 tokenId;
        uint256 rarityLevel; // 0 = Basic, 1 = Normal, 2 = Rare, 3 = Epic ,4=Exclusive
    }

    assignedCategory[] public assignedCategories;

    // tokenId => uri
    mapping(uint256 => string) private _tokenURIs;

    address payable builder; // 10%

    address payable marketingA; // 2%

    address payable marketingB; // 4%

    mapping(address => bool) public whitelist;

    string private _baseURIextended;

    uint256 listingPrice = 0.3 ether;
    uint256 whitelistPrice = 0.2 ether;

    mapping(address => uint256) public partnerBalances;

    bool private revealed = false;

    string private prerevealUrl =
        "https://ipfs.io/ipfs/QmXEB9R5iTh7cLNMjBJeyCdsdLik3ZNmfVdcvKkmabtJ12"; //for dev

    constructor(
        address _builder,
        address _marketingA,
        address _marketingB
    ) public ERC721("Meetsmeta", "MM") {
        builder = payable(_builder);
        marketingA = payable(_marketingA);
        marketingB = payable(_marketingB);
        partnerBalances[msg.sender] = 0 ether;
        partnerBalances[_builder] = 0 ether;
        partnerBalances[_marketingA] = 0 ether;
        partnerBalances[_marketingB] = 0 ether;
    }

    // PUBLIC

    function mintPasses(string memory tokenURI)
        public
        payable
        returns (uint256)
    {
        //this is for dev it will change for prod
        require(totalSupply > _tokenIds.current(), "Minting Finished");
        if (whitelist[msg.sender] == true && balanceOf(msg.sender) < 5) {
            require(msg.value == whitelistPrice, "Incorrect Amount.");
        } else {
            require(msg.value == listingPrice, "Incorrect Amount.");
        }

        uint256 rad = random();
        uint256 assignCat = assignCategory(rad);

        require(assignCat < 5, "Minting Finish");

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        if (whitelist[msg.sender] == true) {
            partnerBalances[owner()] = partnerBalances[owner()].add(0.168 ether);// 84%
            partnerBalances[builder] = partnerBalances[builder].add(0.02 ether);// 10%
            partnerBalances[marketingA] = partnerBalances[marketingA].add(0.004 ether);// 2%
            partnerBalances[marketingB] = partnerBalances[marketingB].add(0.008 ether);// 4%
        } else {
            partnerBalances[owner()] = partnerBalances[owner()].add(0.252 ether);// 84%
            partnerBalances[builder] = partnerBalances[builder].add(0.03 ether);// 10%
            partnerBalances[marketingA] = partnerBalances[marketingA].add(0.006 ether);// 2%
            partnerBalances[marketingB] = partnerBalances[marketingB].add(0.012 ether);// 4%
        }

        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        assignedCategories.push(
            assignedCategory(msg.sender, newItemId, assignCat)
        );
        return newItemId;
    }

    modifier checksBeforeWithdraw(address _partner){
        require(msg.sender == _partner, "Only partners can request payout");
        require(partnerBalances[_partner] > 0,"Nothing to withdraw");
        _;
    }

    function requestPayout() public checksBeforeWithdraw(msg.sender) {
        payable(msg.sender).transfer(partnerBalances[msg.sender]);
        partnerBalances[msg.sender] = 0;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (revealed == true) {
            string memory _tokenURI = _tokenURIs[tokenId];
            string memory base = _baseURI();

            // If there is no base URI, return the token URI.
            if (bytes(base).length == 0) {
                return _tokenURI;
            }
            // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
            if (bytes(_tokenURI).length > 0) {
                return string(abi.encodePacked(base, _tokenURI));
            }
            // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
            return string(abi.encodePacked(base, tokenId.toString()));
        } else {
            return prerevealUrl;
        }
    }

    // PUBLIC ONLY OWNER

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function whitelistAddress(address[] addrs) public onlyOwner {
        for (uint i = 0; i < addrs.length; i++) {
            whitelist[addrs[i]] = true;
        }
    }

    function revealCollection(bool _res) public onlyOwner {
        revealed = _res;
    }

    function swipOut() public onlyOwner {
        // transfer to all accounts the balances and the reset to the owner
        if(partnerBalances[owner()] > 0){
            payable(owner()).transfer(partnerBalances[owner()]);
            partnerBalances[owner()] = 0;
        }
        if(partnerBalances[builder] > 0){
            payable(builder).transfer(partnerBalances[builder]);
            partnerBalances[builder] = 0;
        }
        if(partnerBalances[marketingA] > 0){
           payable(marketingA).transfer(partnerBalances[marketingA]);
           partnerBalances[marketingA] = 0;
        }
        if(partnerBalances[marketingB] > 0){
           payable(marketingB).transfer(partnerBalances[marketingB]);
           partnerBalances[marketingB] = 0;
        }

    }

    // INTERNAL

    function assignCategory(uint256 _rad) internal returns (uint256) {
        uint256 res;

        if (_rad == 0 && Basic.current() < BasicSupply) {
            Basic.increment();
            return 0;
        } else {
            res = otherOption();
            return res;
        }
        if (_rad == 1 && Normal.current() < NormalSupply) {
            Normal.increment();
            return 1;
        } else {
            res = otherOption();
            return res;
        }

        if (_rad == 2 && Rare.current() < RareSupply) {
            Rare.increment();
            return 2;
        } else {
            res = otherOption();
            return res;
        }

        if (_rad == 3 && Epic.current() < EpicSupply) {
            Epic.increment();
            return 3;
        } else {
            res = otherOption();
            return res;
        }

        if (_rad == 4 && Exclusive.current() < ExclusiveSupply) {
            Exclusive.increment();
            return 4;
        } else {
            res = otherOption();
            return res;
        }

        return 5;
    }

    // if the assignCategory failed then this function will be called.
    function otherOption() internal returns (uint256) {
        if (Basic.current() < BasicSupply) {
            Basic.increment();
            return 0;
        } else if (Normal.current() < NormalSupply) {
            Normal.increment();
            return 1;
        } else if (Rare.current() < RareSupply) {
            Rare.increment();
            return 2;
        } else if (Epic.current() < EpicSupply) {
            Epic.increment();
            return 3;
        } else if (Exclusive.current() < ExclusiveSupply) {
            Exclusive.increment();
            return 4;
        }

        return 5;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function random() internal view returns (uint256) {
        return
            uint256(
                keccak256(abi.encodePacked(block.timestamp, block.difficulty))
            ).mod(5);
    }


}
