// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Marketplace.sol";

/// @title NFT Collection SRO.
/// @author Team SarahRo (SRO).
/// @notice Create a NFT SRO Collection contract for the marketplace.
/// @dev This swap connects to a ERC20 contract (Marketplace.sol).

contract SRO721 is ERC721, ERC721Enumerable, ERC721URIStorage {
    using Counters for Counters.Counter;

    // Structure
    struct Nft {
        address author;
        uint256 timestamp;
        uint8 royalties;
        uint32 likes;
        string title;
        string description;
    }

    // State variables
    Marketplace private _marketAddress;
    Counters.Counter private _nftIds; 
    mapping(uint256 => Nft) private _nfts; 
    mapping(address => mapping(uint256 => bool)) private _liked; 
    // TODO Changement pour enumerable pour éviter les limites de gaz / temps d'exécution.
    mapping(address => uint256[]) private _authorToIds;

    // Events
    event Created(address indexed author, uint256 indexed nftId);
    event Liked(address indexed user, uint256 indexed nftId, bool isLike); 

    // Constructor
    constructor(address marketplaceAddress) ERC721("ERC721", "721") {
        _marketAddress = Marketplace(marketplaceAddress); 
    }

    /// @notice The create function allows to create new NFT. 
    /// @dev The receive function is public.
    /// @param royalties_ Royalties for creator of NFT - Require (max amount is 50%).
    /// @param title_ Title of NFT.
    /// @param description_ Description of NFT.
    /// @param uri_ IPFS Link of NFT.
    /// @return ID.

    function create(
        uint8 royalties_,
        string memory title_,
        string memory description_,
        string memory uri_
    ) public returns (uint256) {
        require(royalties_ <= 50, "SRO721: royalties max amount is 50%");
        _nftIds.increment();
        uint256 currentId = _nftIds.current();
        uint256 timestamp = block.timestamp;
        _safeMint(_msgSender(), currentId);
        _setTokenURI(currentId, uri_);
        _nfts[currentId] = Nft(_msgSender(), timestamp, royalties_, 0, title_, description_);
        _authorToIds[_msgSender()].push(currentId);
        emit Created(_msgSender(), currentId); 
        return currentId; 
    }

    /// @notice The like function allows you to like or unlike a nft. Require(limit like to only existing nft).
    /// @dev The receive function is public.
    /// @param nft Royalties for creator of NFT - Require (max amount is 50%).
    /// @return bool.

    // Todo : Changement Bool par Uint.

    function like(uint256 nft) public returns (bool) {
        require(nft <= totalSupply(), "SRO721: Out of bounds");
        require(nft > 0, "SRO721: Out of bounds");
        bool liked = _liked[_msgSender()][nft];
        _liked[_msgSender()][nft] = !liked;
        liked ? _nfts[nft].likes -= 1 : _nfts[nft].likes += 1;
        emit Liked(_msgSender(), nft, !liked);
        return !liked;
    }

    /// @notice Check the NFT by ID.
    /// @dev The getNftById function is public view.
    /// @return ID of NFT.
    
    function getNftById(uint256 id) public view returns (Nft memory) {
        return _nfts[id];
    }

    /// @notice Check the NFT by Author.
    /// @dev The getNftByAuthorAt function public wiew and via index access by enumeration (Work with getNftByAuthorTotal).
    /// @param author Author of NFT.
    /// @param index Index of author.
    /// @return Author of NFT.
            
    function getNftByAuthorAt(address author, uint256 index) public view returns (uint256) {
        return _authorToIds[author][index];
    }

    /// @notice Check the total NFTs created by the author.
    /// @dev The getNftByAuthorTotal function public wiew and access by enumeration.
    /// @param author Author of NFT.
    /// @return Total NFT.

    function getNftByAuthorTotal(address author) public view returns (uint256) {
        return _authorToIds[author].length;
    }

    /// @notice Check if the address liked as NFT.
    /// @dev The isLiked function public view.
    /// @param account Account of like.
    /// @param id Id of NFT.
    /// @return Bool.

    function isLiked(address account, uint256 id) public view returns (bool) {
        return _liked[account][id];
    }
  
    /// @notice Check the marketplace address.
    /// @dev The marketAddress function public view.
    /// @return Address of marketplace.

    function marketAddress() public view returns (address) {
        return address(_marketAddress);
    }

    /// @notice inherits of tokenURI and Override (required).
    /// @dev The tokenURI function is public view and override(ERC721, ERC721URIStorage).
    /// @param tokenId Id of NFT.
    /// @return TokenURI.

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /// @notice inherits of supportsInterface and Override (required).
    /// @dev The supportsInterface function is public view and override(ERC721, ERC721Enumerable).
    /// @param interfaceId Id of interface.
    /// @return SupportsInterface.

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
     
    /// @notice inherits of _beforeTokenTransfer and we check that the NFT that is trying to be transferred, we check its status on the market if it is on sale no exchange possible.
    /// @dev The _beforeTokenTransfer function is public view and override(ERC721, ERC721Enumerable).
    /// @param from Id of sender.
    /// @param to address of recipient.
    /// @param tokenId Id of token.
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
        bool onSale = _marketAddress.isOnSale(address(this), tokenId);
        require(!onSale, "SRO721: you cannot transfer your nft while it is on sale");
    }
    
    /// @notice inherits of _burn and Override (required).
    /// @dev The _burn function is internal and override(ERC721, ERC721Enumerable).
    /// @param tokenId Id of token.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}
