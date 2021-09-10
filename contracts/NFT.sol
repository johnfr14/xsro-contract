// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
// I
import "./Marketplace.sol";

/**
 * NFT Collection SRO
 */
contract SRO721 is ERC721, ERC721Enumerable, ERC721URIStorage {
    using Counters for Counters.Counter;

    /**
     * Marketplace Address to check order status for the _beforeTokenTransfer hook
     */
    Marketplace private _marketAddress;

    struct Nft {
        address author;
        uint256 timestamp;
        uint8 royalties;
        uint32 likes;
        string title;
        string description;
    }

    Counters.Counter private _nftIds; // incremente count creation nft
    mapping(uint256 => Nft) private _nfts; // id to struct (Commence à 1)
    mapping(address => mapping(uint256 => bool)) private _liked; // mapping on all nfts liked by the address 
    // TODO change for enumerable to prevent gas limits / execution time
    mapping(address => uint256[]) private _authorToIds; // tableau createur ID (ID des NFT creer)

    // Event
    event Created(address indexed author, uint256 indexed nftId); // List des NFT crée
    event Liked(address indexed user, uint256 indexed nftId, bool isLike); // event like

    constructor(address marketplaceAddress) ERC721("ERC721", "721") {
        _marketAddress = Marketplace(marketplaceAddress); // verifier l'ETAT de vente du NFT
    }
    // Create NFT 
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
        _safeMint(_msgSender(), currentId); // /!\ Safemint : L'adress qui recoi le token est capable de gerer le token 
        _setTokenURI(currentId, uri_); // ID -> IPFS
        _nfts[currentId] = Nft(_msgSender(), timestamp, royalties_, 0, title_, description_); // Remplir la struct du NFT (Like default : 0)
        _authorToIds[_msgSender()].push(currentId); // Maping author 
        emit Created(_msgSender(), currentId); // Event Creation 
        return currentId; // Return ID
    }

    /**
     * function to like or remove like from an nft
     * require to limit like to only existing nft
     // Todo : Refléchire Changement Bool par Uint .
     */
    function like(uint256 nft) public returns (bool) {
        require(nft <= totalSupply(), "SRO721: Out of bounds"); // Evite un like inutil (Limiter au NFT qui existe)
        require(nft > 0, "SRO721: Out of bounds");
        bool liked = _liked[_msgSender()][nft];
        _liked[_msgSender()][nft] = !liked;
        liked ? _nfts[nft].likes -= 1 : _nfts[nft].likes += 1;
        emit Liked(_msgSender(), nft, !liked);
        return !liked;
    }

    // Check NFT par ID
    function getNftById(uint256 id) public view returns (Nft memory) {
        return _nfts[id];
    }
    // Table : NFT par author via index accès par énumération (Travail avec getNftByAuthorTotal)
    function getNftByAuthorAt(address author, uint256 index) public view returns (uint256) {
        return _authorToIds[author][index];
    }
    // Total des NFT creer par l'auteur accès par énumération (Travail avec getNftByAuthorAt)
    function getNftByAuthorTotal(address author) public view returns (uint256) {
        return _authorToIds[author].length;
    }
    // tel adresse a like tel NFT
    function isLiked(address account, uint256 id) public view returns (bool) {
        return _liked[account][id];
    }

    // adress marketplace
    function marketAddress() public view returns (address) {
        return address(_marketAddress);
    }

    // Heritance -> Override (obligatoire)
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    // HERITAGE
    // Herite du _beforeTokenTransfer et l'on verifie que le NFT qui essaie d'etre transferer, on verifie son Etat sur le market si il est en vente pas d'échange possible
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
        bool onSale = _marketAddress.isOnSale(address(this), tokenId);
        require(!onSale, "SRO721: you cannot transfer your nft while it is on sale");
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}
