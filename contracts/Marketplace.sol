// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Marketplace {
    using Counters for Counters.Counter;

    IERC20 private _token;

    enum Status {
        Inactive,
        OnSale,
        Sold,
        Cancelled
    }

    struct MarketNft {
        Status status;
        uint256 nftId;
        uint256 price;
        address seller;
        address collection;
    }

    Counters.Counter private _saleIds;
    mapping(uint256 => MarketNft) private _sales;
    mapping(address => mapping(uint256 => uint256)) private _saleByCollectionId;

    // TODO events

    constructor(address xsroAddress) {
        _token = IERC20(xsroAddress);
    }

    /**
     * TODO Only authorize collection address from our NFT collection factory
     */
    function createSale(
        address collectionAddress,
        uint256 nftId,
        uint256 price
    ) public {
        IERC721 collection = IERC721(collectionAddress);
        address owner = collection.ownerOf(nftId);
        require(msg.sender == owner, "Markerplace: you must be the owner of this nft");
        require(
            collection.getApproved(nftId) == address(this) || collection.isApprovedForAll(msg.sender, address(this)),
            "Marketplace: you need to approve this contract"
        );
        _saleIds.increment();
        uint256 currentId = _saleIds.current();
        _sales[currentId] = MarketNft(Status.OnSale, nftId, price, msg.sender, collectionAddress);
        _saleByCollectionId[collectionAddress][nftId] = currentId;
    }

    // function change price
    function setPrice(uint256 saleId, uint256 newPrice) public {
        address owner = _sales[saleId].seller;
        require(msg.sender == owner, "Markerplace: you must be the owner of this nft");
        _sales[saleId].price = newPrice;
    }

    function removeSale(uint256 saleId) public {
        address owner = _sales[saleId].seller;
        require(msg.sender == owner, "Markerplace: you must be the owner of this nft");
        _sales[saleId].status = Status.Cancelled;
    }

    // buy function
    function buyNft(uint256 saleId) public {
        require(_sales[saleId].status == Status.OnSale, "Marketplace: this nft is not on sale");
        MarketNft memory item = _sales[saleId];
        require(_token.balanceOf(msg.sender) >= item.price, "Marketplace: not enough xSRO");
        _sales[saleId].status = Status.Sold;
        _token.transferFrom(msg.sender, item.seller, item.price);
        IERC721(item.collection).safeTransferFrom(item.seller, msg.sender, item.nftId);
    }

    function token() public view returns (address) {
        return address(_token);
    }

    function getSale(uint256 saleId) public view returns (MarketNft memory) {
        return _sales[saleId];
    }

    function getSaleId(address collection, uint256 nftId) public view returns (uint256) {
        return _saleByCollectionId[collection][nftId];
    }

    function isOnSale(address collection, uint256 nftId) public view returns (bool) {
        uint256 saleId = getSaleId(collection, nftId);
        return _sales[saleId].status == Status.OnSale;
    }

    function totalSale() public view returns (uint256) {
        return _saleIds.current();
    }
}
