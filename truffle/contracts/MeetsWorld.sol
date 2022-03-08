// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MeetsWorld is Ownable, ERC721 {
    using Counters for Counters.Counter;

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

    address payable primaryOwner;

    address payable builder; // 10%

    address payable marketingA; // 2%

    address payable marketingB; // 4%

    address[] public whitelist;

    string private _baseURIextended;

    uint256 listingPrice = 0.3 ether;
    uint256 whitelistPrice = 0.2 ether;

    uint256 primaryOwnerBalance = 0 ether;
    uint256 builderBalance = 0 ether;
    uint256 marketingABalance = 0 ether;
    uint256 marketingBBalance = 0 ether;

    bool private revealed = false;

    string private prerevealUrl =
        "https://ipfs.io/ipfs/QmXEB9R5iTh7cLNMjBJeyCdsdLik3ZNmfVdcvKkmabtJ12"; //for dev

    constructor(
        address _builder,
        address _marketingA,
        address _marketingB
    ) public ERC721("Meetsmeta", "MM") {
        primaryOwner = payable(msg.sender);
        builder = payable(_builder);
        marketingA = payable(_marketingA);
        marketingB = payable(_marketingB);
    }

    // PUBLIC

    function mintPasses(string memory tokenURI)
        public
        payable
        returns (uint256)
    {
        //this is for dev it will change for prod
        require(totalSupply > _tokenIds.current(), "Minting Finished");
        if (whitelist[msg.sender] == true) {
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
            primaryOwnerBalance += 0.168 ether; // 84%
            builderBalance += 0.02 ether; // 10%
            marketingABalance += 0.004 ether; // 2%
            marketingBBalance += 0.008 ether; // 4%
        } else {
            primaryOwnerBalance += 0.252 ether; // 84%
            builderBalance += 0.03 ether; // 10%
            marketingABalance += 0.006 ether; // 2%
            marketingBBalance += 0.012 ether; // 4%
        }

        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        assignedCategories.push(
            assignedCategory(msg.sender, newItemId, assignCat)
        );
        return newItemId;
    }

    function builderPayout() public {
        require(msg.sender == builder, "Only the builder can payout");
        payable(builder).transfer(builderBalance);
        builderBalance = 0;
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
            return preprerevealUrl;
        }
    }

    // PUBLIC ONLY OWNER

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function whitelistAddress(address addr) public onlyOwner {
        whitelist.push(addr);
    }

    function revealCollection(bool _res) public onlyOwner {
        revealed = _res;
    }

    function swipOut() public onlyOwner {
        // transfer to all accounts the balances and the reset to the owner
        // payable(primaryOwner).transfer(address(this).balance);
        uint256 balance = address(this).balance;
        payable(primaryOwner).transfer(balance);
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
            ) % 5;
    }


}
