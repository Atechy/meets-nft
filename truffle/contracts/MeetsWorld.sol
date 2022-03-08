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
   
    uint256 public BasicSupply = 1; //for dev
    uint256 public NormalSupply = 1; 
    uint256 public RareSupply = 1; 
    uint256 public EpicSupply = 1; 
    uint256 public ExclusiveSupply = 4; 

    uint256 public totalSupply = 8; //for dev

    using Strings for uint256;

    struct assignedCatigorie
        {
        address addr; // address of the owner
        uint256 tokenId;
        uint256 rarityLevel;  // 0 = Basic, 1 = Normal, 2 = Rare, 3 = Epic ,4=Exclusive
    }

    assignedCatigorie[] public assignedCatigories;

    mapping(uint256 => string) private _tokenURIs;

    address payable primary_Owner;

    address payable sec_Owner; //for dev

    string private _baseURIextended;

    uint256 listingPrice = 0.001 ether; //for dev

    bool private revealed=false;

    string private revealUrl = "https://ipfs.io/ipfs/QmXEB9R5iTh7cLNMjBJeyCdsdLik3ZNmfVdcvKkmabtJ12"; //for dev
    
    constructor(address _sec_Owner) public ERC721("MeetsWorld", "MW") {
           primary_Owner=payable(msg.sender);
           sec_Owner=payable(_sec_Owner);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

  /**
    0-->Basic
    1-->Normal
    2-->Rare
    3-->Epic
    4-->Exclusive
    5-->notAssigned
     */
    //check for other option
   function otherOption()internal returns(uint256){

       if(Basic.current()<BasicSupply){
            Basic.increment();
            return 0;
       }else if(Normal.current()<NormalSupply){
            Normal.increment();
            return 1;
       }else if(Rare.current()<RareSupply){
            Rare.increment();
            return 2;
       }else if(Epic.current()<EpicSupply){
            Epic.increment();
            return 3;
       }else if(Exclusive.current()<ExclusiveSupply){
            Exclusive.increment();
            return 4;
       }

       return 5;

    }
    function assignCatigories(uint256 _rad)internal returns(uint256){

          uint256 res;

          if(_rad==0 && Basic.current()<BasicSupply){
              Basic.increment();
              return 0;
          }else{
            res=otherOption();
            return res;
          }
          if(_rad==1 && Normal.current()<NormalSupply){
              Normal.increment();
              return 1;
          }else{
            res=otherOption();
            return res;
          }

          if(_rad==2 && Rare.current()<RareSupply){
              Rare.increment();
              return 2;
          }else{
            res=otherOption();
            return res;
          }

          if(_rad==3 && Epic.current()<EpicSupply){
              Epic.increment();
              return 3;
          }else{
            res=otherOption();
            return res;
          }

         if(_rad==4 && Exclusive.current()<ExclusiveSupply){
              Exclusive.increment();
              return 4;
          }else{
            res=otherOption();
            return res;
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

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
       if (revealed == true){
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
       return super.tokenURI(tokenId);
         
       }else{
        return revealUrl;
       }
    }

    function  revealCollection(bool _res) public onlyOwner{
        revealed=_res;
    }

     function random() internal view returns (uint) {
        
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty))) % 5;
                                                                                    
     }


    function mintPasses(string memory tokenURI) public payable returns (uint256) {
        //this is for dev it will change for prod
        require(totalSupply>_tokenIds.current(),"Minting Finish!!!");
        require(msg.value==listingPrice,"Incorrect Amount.");
       
        uint256 rad=random();
        uint256 assignCat=assignCatigories(rad);
        require(assignCat<5,"Minting Finish");
         _tokenIds.increment();
        if(_tokenIds.current()!=1 && _tokenIds.current()%2==1){
                payable(sec_Owner).transfer(msg.value);
        }
        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        assignedCatigories.push(assignedCatigorie(msg.sender,newItemId,assignCat));
        return newItemId;
    }


    function swipOut() public onlyOwner{

       // payable(primary_Owner).transfer(address(this).balance);
        uint balance = address(this).balance;
        payable(primary_Owner).transfer(balance);
        
    }

}
