// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title Marketplace.
/// @author Team SarahRo (SRO).
/// @notice Create a NFT SRO Collection contract for the marketplace.
/// @dev This Marketplace connects to a ERC20 and ERC721 contracts by import OpenZeppelin.

contract Marketplace {
    using Counters for Counters.Counter;

    // Enums
    enum Status {
        Inactive,
        OnSale,
        Sold,
        Cancelled
    }

    // Structure
    struct MarketNft {
        Status status;
        uint256 nftId;
        uint256 price;
        address seller;
        address collection;
    }

    // State variables
    IERC20 private _token;
    Counters.Counter private _saleIds;
    mapping(uint256 => MarketNft) private _sales; // struc des vente
    mapping(address => mapping(uint256 => uint256)) private _saleByCollectionId; // retrouver la vente via l'adresse et l'id

    // Events
    event Registered(address indexed seller, uint256 indexed saleId); // Vente créé
    event PriceChanged(uint256 indexed saleId, uint256 price); // Prix MAJ
    event Cancelled(address indexed seller, uint256 indexed saleId); // Cancel
    event Sold(address indexed buyer, uint256 indexed saleId); // Sold

    // Constructor
    constructor(address xsroAddress) {
        _token = IERC20(xsroAddress);
    }

    // Modifiers

    /// @notice Check that the NFT is on sale.
    /// @param saleId Id of sale.

    modifier onSale(uint256 saleId) {
        require(_sales[saleId].status == Status.OnSale, "Marketplace: this nft is not on sale");
        _;
    }

    /// @notice Check that it is the seller of the nft.
    /// @param saleId Id of sale.

    modifier onlySeller(uint256 saleId) {
        address seller = _sales[saleId].seller;
        require(msg.sender == seller, "Markerplace: you must be the seller of this nft");
        _;
    }

    // TODO Only authorize collection address from our NFT collection factory.

    /// @notice Create a sale with SRO collection.
    /// @dev The createSale function is public.
    /// @param collectionAddress Address of collection.
    /// @param nftId Id of nft.
    /// @param price Price to defined for sale.
    /// @return Bool.

    function createSale(
        address collectionAddress,
        uint256 nftId,
        uint256 price
    ) public returns (bool) {
        require(!isOnSale(collectionAddress, nftId), "Marketplace: This nft is already on sale");
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
        emit Registered(msg.sender, currentId);
        return true;
    }

    /// @notice Set the price of the NFT currently on the marketplace.
    /// @dev The setPrice function is public with modifier(onSale and onlySeller).
    /// @param saleId Id of sale.
    /// @param newPrice New price to defined.
    /// @return Bool.

    // Todo : Ajouter event pour récuperer l'ancien prix.

    function setPrice(uint256 saleId, uint256 newPrice) public onSale(saleId) onlySeller(saleId) returns (bool) {
        _sales[saleId].price = newPrice;
        emit PriceChanged(saleId, newPrice);
        return true;
    }

    /// @notice This function allows to remove the NFT on the marketplace.
    /// @dev The removeSale function is public with modifier(onSale and onlySeller).
    /// @param saleId Id of sale.
    /// @return Bool.

    function removeSale(uint256 saleId) public onSale(saleId) onlySeller(saleId) returns (bool) {
        MarketNft memory item = _sales[saleId];
        _sales[saleId].status = Status.Cancelled;
        delete _saleByCollectionId[item.collection][item.nftId];
        emit Cancelled(msg.sender, saleId);
        return true;
    }

    /// @notice This function allows to buy the NFT on the marketplace.
    /// @dev The buyNft function is public with modifier(onSale).
    /// @param saleId Id of sale.
    /// @return Bool.

    function buyNft(uint256 saleId) public onSale(saleId) returns (bool) {
        MarketNft memory item = _sales[saleId];
        require(_token.balanceOf(msg.sender) >= item.price, "Marketplace: not enough xSRO");
        require(
            _token.allowance(msg.sender, address(this)) >= item.price,
            "Marketplace: you need to approve this contract to buy"
        );
        _sales[saleId].status = Status.Sold;
        delete _saleByCollectionId[item.collection][item.nftId];
        _token.transferFrom(msg.sender, item.seller, item.price);
        IERC721(item.collection).safeTransferFrom(item.seller, msg.sender, item.nftId);
        emit Sold(msg.sender, saleId);
        return true;
    }

    /// @notice Check token address.
    /// @dev The token function is public view.
    /// @return Address of token.

    function token() public view returns (address) {
        return address(_token);
    }

    /// @notice Check status of the sale.
    /// @dev The getSale function is public view.
    /// @param saleId Id of sale.
    /// @return Status of the sale (on sale, address, seller ...).

    function getSale(uint256 saleId) public view returns (MarketNft memory) {
        return _sales[saleId];
    }

    /// @notice Check id of status of the sale.
    /// @dev The getSaleId function is public view.
    /// @param collection Address of collection.
    /// @param nftId Id of NFT.
    /// @return Id of sale.

    function getSaleId(address collection, uint256 nftId) public view returns (uint256) {
        return _saleByCollectionId[collection][nftId];
    }

    /// @notice Check if NFT is on sale.
    /// @dev The isOnSale function is public view.
    /// @param collection Address of collection.
    /// @param nftId Id of NFT.
    /// @return Bool.

    function isOnSale(address collection, uint256 nftId) public view returns (bool) {
        uint256 saleId = getSaleId(collection, nftId);
        return _sales[saleId].status == Status.OnSale;
    }

    /// @notice Number of times the CreateSale function is validated (done).
    /// @dev The isOnSale function is public view.
    /// @return Number of created sale validated.

    function totalSale() public view returns (uint256) {
        return _saleIds.current();
    }
}
