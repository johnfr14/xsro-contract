// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Marketplace {
    using Counters for Counters.Counter;

    
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

    IERC20 private _token;
    Counters.Counter private _saleIds;
    mapping(uint256 => MarketNft) private _sales; // struc des vente
    mapping(address => mapping(uint256 => uint256)) private _saleByCollectionId; // retrouver la vente via l'adresse et l'id 

    event Registered(address indexed seller, uint256 indexed saleId); // Vente créé
    event PriceChanged(uint256 indexed saleId, uint256 price); // Prix MAJ
    event Cancelled(address indexed seller, uint256 indexed saleId); // Cancel
    event Sold(address indexed buyer, uint256 indexed saleId); // Sold

    constructor(address xsroAddress) {
        _token = IERC20(xsroAddress);
    }

    // Modifier si le NFT soit en vente 
    modifier onSale(uint256 saleId) { 
        require(_sales[saleId].status == Status.OnSale, "Marketplace: this nft is not on sale");
        _;
    }

    // Que le vendeur 
    modifier onlySeller(uint256 saleId) {
        address seller = _sales[saleId].seller;
        require(msg.sender == seller, "Markerplace: you must be the seller of this nft");
        _;
    }

    /**
     * TODO Only authorize collection address from our NFT collection factory
     
     */

    function createSale(
        address collectionAddress,
        uint256 nftId,
        uint256 price
    ) public returns (bool) {
        // require contract is part of our Collection 
        require(!isOnSale(collectionAddress, nftId), "Marketplace: This nft is already on sale"); // Tu peux pas recreer une vente si NFT en vente
        IERC721 collection = IERC721(collectionAddress); // Connecter la collection / Check que le msg sender c'est owner 
        address owner = collection.ownerOf(nftId); // Verifie que c'est bien le owner qui à le nft
        require(msg.sender == owner, "Markerplace: you must be the owner of this nft");
        require(
            collection.getApproved(nftId) == address(this) || collection.isApprovedForAll(msg.sender, address(this)), // Approuve la market (1) Adresse pour un NFT ou (2) aprouve for all pour tout les NFT 
            "Marketplace: you need to approve this contract"
        );
        _saleIds.increment(); 
        uint256 currentId = _saleIds.current(); 
        _sales[currentId] = MarketNft(Status.OnSale, nftId, price, msg.sender, collectionAddress);
        _saleByCollectionId[collectionAddress][nftId] = currentId;
        emit Registered(msg.sender, currentId);
        return true;
    }

    // function change price 
    // Todo : Event ancien prix 
    function setPrice(uint256 saleId, uint256 newPrice) public onSale(saleId) onlySeller(saleId) returns (bool) {
        _sales[saleId].price = newPrice;
        emit PriceChanged(saleId, newPrice);
        return true;
    }

    // function remove sale
    function removeSale(uint256 saleId) public onSale(saleId) onlySeller(saleId) returns (bool) {
        MarketNft memory item = _sales[saleId];
        _sales[saleId].status = Status.Cancelled;
        delete _saleByCollectionId[item.collection][item.nftId];
        emit Cancelled(msg.sender, saleId);
        return true;
    }

    // buy function
    function buyNft(uint256 saleId) public onSale(saleId) returns (bool) {
        MarketNft memory item = _sales[saleId];
        require(_token.balanceOf(msg.sender) >= item.price, "Marketplace: not enough xSRO");
        require(
            _token.allowance(msg.sender, address(this)) >= item.price,
            "Marketplace: you need to approve this contract to buy"
        );
        _sales[saleId].status = Status.Sold; // Dit vendu 
        delete _saleByCollectionId[item.collection][item.nftId]; // Delete NFT saleBycolectionId (colection + Nft ID)
        _token.transferFrom(msg.sender, item.seller, item.price); // 
        IERC721(item.collection).safeTransferFrom(item.seller, msg.sender, item.nftId); // Saler vers acheteur du NFT
        emit Sold(msg.sender, saleId);
        return true;
    }

    function token() public view returns (address) {
        return address(_token);
    }
    // Etat de la vente (on sold, adress, vendeur ...)
    function getSale(uint256 saleId) public view returns (MarketNft memory) {
        return _sales[saleId];
    }

    function getSaleId(address collection, uint256 nftId) public view returns (uint256) {
        return _saleByCollectionId[collection][nftId];
    }

    // Si tel NFT est en vente 
    function isOnSale(address collection, uint256 nftId) public view returns (bool) {
        uint256 saleId = getSaleId(collection, nftId);
        return _sales[saleId].status == Status.OnSale;
    }

    // Nombre de fois que la fonction CreateSale et validé (done)
    function totalSale() public view returns (uint256) {
        return _saleIds.current();
    }
}
