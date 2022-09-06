// SPDX-License-Identifier: MIT


pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IConfig.sol";
import "hardhat/console.sol";

contract marketplace is ReentrancyGuard , Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold; 
    

    uint256 totalVolume;
    
    address private config;

    constructor(address _config) {
        config = _config;
    }

    receive() external payable{

    }

    fallback() external payable{

    }



    struct MarketItem {

        uint itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
        uint256 amount;

    }

    mapping(uint256 => MarketItem) public idToMarketItem;
    mapping(uint256 => mapping(address=>bool)) public exists;
    mapping(uint256 => mapping(address=>uint256)) public itemIDs_;




    event MarketItemCreated (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );


 

function getNftType(address nftContract) public view returns(uint256){
  if(IERC721(nftContract).supportsInterface(0x80ac58cd))
      return 0 ;
    else
      return 1 ;
  }

function transferNFT (
  address nftContract,
  address from,
  address to,
  uint256 tokenId,
  uint256 amount
) public payable returns(bool){

    if(getNftType(nftContract) == 0){
        
        IERC721(nftContract).transferFrom(from, to, tokenId);
            return true ; 
        }else if (getNftType(nftContract) == 1) {
        IERC1155(nftContract).safeTransferFrom(from, to, tokenId , amount , "");
            return true ; 
        }else{
        require(false , "cant transfer");
        }

    }

/* Places an item for sale on the marketplace */
function createMarketItem(
address nftContract,
uint256 tokenId,
uint256 price,
uint256 _amount
) public payable nonReentrant returns(uint256) {
require(price > 0, "Price must be at least 1 wei");
_itemIds.increment();
uint256 itemId = _itemIds.current();

exists[tokenId][nftContract] = true;
itemIDs_[tokenId][nftContract] = _itemIds.current();
idToMarketItem[itemId] =MarketItem(
itemId,
nftContract,
tokenId,
payable(msg.sender),
payable(address(0)),
price,
false,
_amount
);

transferNFT (
nftContract,
_msgSender(),
address(this),
tokenId,
_amount
);

emit MarketItemCreated(
itemId,
nftContract,
tokenId,
msg.sender,
address(0),
price,
false
);

return itemId;
}

/* Creates the sale of a marketplace item */
/* Transfers ownership of the item, as well as funds between parties */


function createMarketSale(
address nftContract,
uint256 itemId
) public nonReentrant {
MarketItem memory marketitem = idToMarketItem[itemId];
uint256 amount = marketitem.amount;

uint price = idToMarketItem[itemId].price;
uint tokenId = idToMarketItem[itemId].tokenId;

console.log(IERC20(IConfig(config).USDG()).allowance(_msgSender(),address(this)));

require(IERC20(IConfig(config).USDG()).allowance(_msgSender(),address(this)) >= price,
 "Please submit the asking price in order to complete the purchase");

exists[tokenId][nftContract] = false;
delete itemIDs_[tokenId][nftContract];

uint256 value = (price/100)*100 - IConfig(config).nft_fee();
IERC20(IConfig(config).USDG()).transferFrom(_msgSender(), idToMarketItem[itemId].seller , value);
IERC20(IConfig(config).USDG()).transferFrom(_msgSender(), IConfig(config).platform() , price - value);


transferNFT (
nftContract,
address(this),
_msgSender(),
tokenId,
amount
);
// idToMarketItem[itemId].owner = payable(msg.sender);
// idToMarketItem[itemId].sold = true;

delete idToMarketItem[itemId];

_itemsSold.increment();
totalVolume += price;

}

function ownerOf(address _nftContract,uint256 tokenID) public view returns(address){
  return idToMarketItem[itemIDs_[tokenID][_nftContract]].seller;
}

/* Returns all unsold market items */
function fetchMarketItems() public view returns (MarketItem[] memory) { 
  uint itemCount = _itemIds.current(); 
  uint unsoldItemCount = _itemIds.current() - _itemsSold.current(); 
  uint currentIndex = 0; 
  
  MarketItem[] memory items = new MarketItem[](unsoldItemCount); 
  for (uint i = 0; i < itemCount; i++) { 
  if (idToMarketItem[i + 1].owner == address(0)) { 
  uint currentId = i + 1; 
  MarketItem storage currentItem = idToMarketItem[currentId]; 
  items[currentIndex] = currentItem; 
  currentIndex += 1; 
  } 
  } 
  return items; 
  } 
  
  /* Returns onlyl items that a user has purchased */ 
  function fetchMyNFTs() public view returns (MarketItem[] memory) { 
  uint totalItemCount = _itemIds.current(); 
  uint itemCount = 0; 
  uint currentIndex = 0; 
  
  for (uint i = 0; i < totalItemCount; i++) { 
  if (idToMarketItem[i + 1].owner == msg.sender) { 
  itemCount += 1; 
  } 
  } 
  
  MarketItem[] memory items = new MarketItem[](itemCount); 
  for (uint i = 0; i < totalItemCount; i++) { 
  if (idToMarketItem[i + 1].owner == msg.sender) { 
  uint currentId = i + 1; 
  MarketItem storage currentItem = idToMarketItem[currentId]; 
  items[currentIndex] = currentItem; 
  currentIndex += 1; 
  } 
  } 
  return items; 
  } 
   
  /* Returns only items a user has created */ 
  function fetchItemsCreated() public view returns (MarketItem[] memory) { 
  uint totalItemCount = _itemIds.current(); 
  uint itemCount = 0; 
  uint currentIndex = 0; 
  
  for (uint i = 0; i < totalItemCount; i++) { 
  if (idToMarketItem[i + 1].seller == msg.sender) { 
  itemCount += 1; 
  } 
  } 
  
  MarketItem[] memory items = new MarketItem[](itemCount); 
  for (uint i = 0; i < totalItemCount; i++) { 
  if (idToMarketItem[i + 1].seller == msg.sender) { 
  uint currentId = i + 1; 
  MarketItem storage currentItem = idToMarketItem[currentId]; 
  items[currentIndex] = currentItem; 
  currentIndex += 1; 
  } 
  } 
  return items; 
  } 
   
  function getListedNFT(uint256 itemId) public view returns( MarketItem[] memory ){ 
  MarketItem[] memory items = new MarketItem[](1); 
  MarketItem storage currentItem = idToMarketItem[itemId]; 
  items[0] = currentItem; 
  return items; 
  } 

    
}