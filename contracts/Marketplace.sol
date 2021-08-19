// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./NFT.sol";
import "./xSRO.sol";

contract Marketplace {
    SarahRO private _token;
    SRO721 private _nft;

    /**
     * struct MarketItem
     * {
     *     uint256 nftId;
     *     uint256 priceSRO;
     *     uint256 priceETH;
     *     address owner;
     * }
     */

    constructor(address xsroAddress, address nftAddress) {
        _token = SarahRO(xsroAddress);
        _nft = SRO721(nftAddress);
    }

    // create sale function

    // buy function
}
