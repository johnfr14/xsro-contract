// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

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

    Counters.Counter private _nftIds;
    mapping(uint256 => Nft) private _nfts; // id to struct
    mapping(address => mapping(uint256 => bool)) private _liked; // mapping on all nfts liked by the address
    // TODO change for enumerable to prevent gas limits / execution time
    mapping(address => uint256[]) private _authorToIds;

    event Created(address indexed author, uint256 indexed nftId);
    event Liked(address indexed user, uint256 indexed nftId, bool isLike);

    constructor(address marketplaceAddress) ERC721("ERC721", "721") {
        _marketAddress = Marketplace(marketplaceAddress);
    }

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
        // setApprovalForAll(_marketAddress, true);
        _nfts[currentId] = Nft(_msgSender(), timestamp, royalties_, 0, title_, description_);
        _authorToIds[_msgSender()].push(currentId);
        emit Created(_msgSender(), currentId);
        return currentId;
    }

    /**
     * function to like or remove like from an nft
     * require to limit like to only existing nft
     */
    function like(uint256 nft) public returns (bool) {
        require(nft <= totalSupply(), "SRO721: Out of bounds");
        require(nft > 0, "SRO721: Out of bounds");
        bool liked = _liked[msg.sender][nft];
        liked ? _nfts[nft].likes -= 1 : _nfts[nft].likes += 1;
        _liked[msg.sender][nft] = !liked;
        emit Liked(msg.sender, nft, !liked);
        return !liked;
    }

    function getNftById(uint256 id) public view returns (Nft memory) {
        return _nfts[id];
    }

    function getNftByAuthorAt(address author, uint256 index) public view returns (uint256) {
        return _authorToIds[author][index];
    }

    function getNftByAuthorTotal(address author) public view returns (uint256) {
        return _authorToIds[author].length;
    }

    function isLiked(address account, uint256 id) public view returns (bool) {
        return _liked[account][id];
    }

    function marketAddress() public view returns (address) {
        return address(_marketAddress);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

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
