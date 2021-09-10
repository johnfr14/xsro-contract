// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./xSRO.sol";

contract SwapSRO is Ownable {
    using Address for address payable;

    SarahRO private _token;
    address private _tokenOwner;
    uint256 private _rate;

    event Swapped(address indexed swapper, uint256 ethAmount, uint256 sroAmount);
    event Withdrew(address indexed owner, uint256 amount);
    event RateChanged(address indexed owner, uint256 newRate);

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

    function withdrawAll() public onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "SwapSRO: nothing to withdraw");
        payable(msg.sender).sendValue(amount);
        emit Withdrew(msg.sender, amount);
    }

    function setRate(uint256 rate_) public onlyOwner {
        require(rate_ > 0, "SwapSRO: rate cannot be 0");
        _rate = rate_;
        emit RateChanged(msg.sender, rate_);
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

    function token() public view returns (address) {
        return address(_token);
    }

    function tokenOwner() public view returns (address) {
        return _tokenOwner;
    }

    function ownerAllowance() public view returns (uint256) {
        return _token.allowance(_tokenOwner, address(this));
    }

    function _swapTokens(address sender, uint256 amount) private {
        // require
        uint256 tokenAmount = amount * _rate;
        require(tokenAmount <= ownerAllowance(), "SwapSRO: you cannot swap more than the allowance");
        _token.transferFrom(_tokenOwner, sender, tokenAmount);
        emit Swapped(sender, amount, tokenAmount);
    }
}
