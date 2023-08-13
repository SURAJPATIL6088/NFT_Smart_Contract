// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// INTERNAL IMPORT FOR NFT-OPENZIPPLINE
import "@openzeppelin/contracts/utils/Counters.sol"; // used as a counter
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Uncomment this line to use console.log
import "hardhat/console.sol";

// contract creation
// inherit the some properties
contract NFTMarketPlace is ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;
    uint256 listingPrice = 0.0015 ether;

    address payable owner;

    // every nft has the different id it will stored in the mapping
    mapping(uint256 => MarketItem) private idMarketItem;

    // it will store the information about nft
    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    // check for owner
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only Onwer of the MarketPlace can change the listing Price"
        );
        _;
    }

    event idMarketItemCreated(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    constructor() ERC721("NFT Metaverse Web3.0 Token", "MYNFTBLK") {
        owner == payable(msg.sender);
    }

    // this will help to update the pricing of the nft
    // this can only person do who is the onwer of that nft
    function updateListingPrice(
        uint256 _listingPrice
    ) public payable onlyOwner {
        listingPrice = _listingPrice;
    }

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    // let create "CREATE NFT TOKEN FUNCTION"
    function createToken(
        string memory tokenURI,
        uint256 price
    ) public payable returns (uint256) {
        // it will be usefull for he token id whenever the token gets created it will update the id of token
        _tokenIds.increment();

        uint256 newTokenId = _tokenIds.current();

        // already defined in the openzepplin library
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        // this will be created my myself
        createMarketItem(newTokenId, price);
        return newTokenId;
    }

    // CREATING THE MARKETITEM
    function createMarketItem(uint256 tokenId, uint256 price) private {
        require(price > 0, "Price must be atleast 1 ETH");
        require(
            msg.value == listingPrice,
            "Price must be equal to Listing Price"
        );

        idMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );

        // from openzepplin
        _transfer(msg.sender, address(this), tokenId);

        emit idMarketItemCreated(
            tokenId,
            msg.sender,
            address(this),
            price,
            false
        );
    }

    // FUNCTION FOR RESALE TOKEN
    function reSellToken(uint256 tokenId, uint256 price) public payable {
        // resell can only done by the onwer of that nft
        require(
            idMarketItem[tokenId].owner == msg.sender,
            "Only Token Owner can perform this Operation"
        );

        require(
            msg.value == listingPrice,
            "Price must be equal to Listing Price"
        );

        idMarketItem[tokenId].sold = false;
        idMarketItem[tokenId].price = price;
        idMarketItem[tokenId].seller = payable(msg.sender);
        idMarketItem[tokenId].owner = payable(address(this));

        _itemsSold.decrement();

        // from openzepplin
        _transfer(msg.sender, address(this), tokenId);
    }

    // FUNCTION CREATE MARKET SALE
    function createMarketSale(uint256 tokenId) public payable {
        // get the price
        uint256 price = idMarketItem[tokenId].price;

        require(
            msg.value == price,
            "Please submit the asking price in order to complete the purchase"
        );

        idMarketItem[tokenId].owner = payable(msg.sender);
        idMarketItem[tokenId].sold = true;
        idMarketItem[tokenId].owner = payable(address(0));
        _itemsSold.increment();

        _transfer(address(this), msg.sender, tokenId);
        payable(owner).transfer(listingPrice);
        payable(idMarketItem[tokenId].seller).transfer(msg.value); 
    }

    // GET THE UN SOLD NFT DATA
    function fetchMarketItem() public view returns (MarketItem[] memory) {
        uint256 itemCount = _tokenIds.current();
        uint256 unSoldItemCount = _tokenIds.current() - _itemsSold.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unSoldItemCount);
        for(uint256 i =0; i<itemCount; i++)
        {
            if(idMarketItem[i+1].owner == address(this)){
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    // PURCHASE THE TOKEN
    function fetchMyNFT() public view returns(MarketItem[] memory) {
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for(uint256 i =0; i<totalCount; i++)
        {
            if(idMarketItem[i+1].owner == msg.sender){
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for(uint256 i =0; i<totalCount; i++){
            if(idMarketItem[i+1].owner == msg.sender){
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;                
            }
        }

        return items;
    }

    // SINGLE USER ITEMS
    function fetchItemsListed() public view returns(MarketItem[] memory)
    {
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        
        for(uint256 i =0; i<totalCount; i++)
        {
            if(idMarketItem[i+1].seller == msg.sender){
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for(uint256 i =0; i<totalCount; i++){
            if(idMarketItem[i+1].seller == msg.sender){
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;                
            }
        }

        return items;     
    }
    
}
