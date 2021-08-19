// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SRO721 is ERC721, ERC721Enumerable, ERC721URIStorage {
    using Counters for Counters.Counter;

    address private _contractAddress;

    struct Nft {
        address author;
        uint256 timestamp;
        uint8 royalties;
        string title;
        string description;
    }

    Counters.Counter private _nftIds;
    mapping(uint256 => Nft) private _nfts; // id to struct

    event Created(address indexed author, uint256 indexed nftId);

    constructor(address marketplaceAddress) ERC721("ERC721", "721") {
        _contractAddress = marketplaceAddress;
    }

    function create(
        uint8 royalties_,
        string memory title_,
        string memory description_,
        string memory uri_
    ) public returns (uint256) {
        // require();
        _nftIds.increment();
        uint256 currentId = _nftIds.current();
        uint256 timestamp = block.timestamp;
        _mint(_msgSender(), currentId);
        _setTokenURI(currentId, uri_);
        setApprovalForAll(_contractAddress, true);
        _nfts[currentId] = Nft(_msgSender(), timestamp, royalties_, title_, description_);
        emit Created(_msgSender(), currentId);
        return currentId;
    }

    function getNftById(uint256 id) public view returns (Nft memory) {
        return _nfts[id];
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
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}
