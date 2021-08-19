// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./xSRO.sol";

contract SwapSRO is Ownable {
    SarahRO private _token;
    address private _tokenOwner;
    uint256 private _rate;

    event Swapped(address indexed swapper, uint256 EthAmount, uint256 SroAmount);

    constructor(address xsroAddress, address tokenOwner_) {
        _token = SarahRO(xsroAddress);
        _tokenOwner = tokenOwner_;
        _rate = 10;
    }

    receive() external payable {
        _swapTokens(msg.sender, msg.value);
    }

    function swapTokens() public payable {
        _swapTokens(msg.sender, msg.value);
    }

    function setRate(uint256 rate_) public onlyOwner {
        _rate = rate_;
    }

    function rate() public view returns (uint256) {
        return _rate;
    }

    function sroToEth(uint256 amount) public view returns (uint256) {
        return amount / _rate;
    }

    function ethToSro(uint256 amount) public view returns (uint256) {
        return amount * _rate;
    }

    function _swapTokens(address sender, uint256 amount) private {
        // require
        uint256 tokenAmount = amount * _rate;
        _token.transferFrom(_tokenOwner, sender, tokenAmount);
        // emit
        emit Swapped(sender, amount, tokenAmount);
    }
}
