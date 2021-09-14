// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
// Todo Import ERC20 ou .xSRO (cf. Marketplace.sol).
import "./xSRO.sol";

/// @title Create Swap contract for xSRO token.
/// @author Team SarahRo (SRO).
/// @notice all users can swap the ETH tokens to xSRO tokens. Exchange is 1 ETH for 1000 xSRO.
/// @dev This swap connects to a ERC20 contract (xSRO.sol).

contract SwapSRO is Ownable {
    using Address for address payable;

    // State variables
    SarahRO private _token; 
    address private _tokenOwner; 
    uint256 private _rate; 
    
    // Events
    event Swapped(address indexed swapper, uint256 ethAmount, uint256 sroAmount); 
    event Withdrew(address indexed owner, uint256 amount); 
    event RateChanged(address indexed owner, uint256 newRate); // Todo recupèrer sur le current front.

    // Constructor
    constructor(address xsroAddress, address tokenOwner_) {
        // Todo Require (token owner = all xsro).
        _token = SarahRO(xsroAddress);
        _tokenOwner = tokenOwner_;
        _rate = 1000;
    }

    /// @notice The receive function allows to send ETH to this address(Metamask to users). 
    /// @dev The receive function is external & payable.
    
    receive() external payable {
        _swapTokens(msg.sender, msg.value);
    }
    /// @notice The receive function allows to swap token.
    /// @dev The receive function is public & payable.

    function swapTokens() public payable {
        _swapTokens(msg.sender, msg.value);
    }

    /// @notice The withdrawAll function allows to retrieves ETH that users have exchanged.
    /// @dev The receive function is public and only the owner can execute it.

    function withdrawAll() public onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "SwapSRO: nothing to withdraw");
        payable(msg.sender).sendValue(amount);
        emit Withdrew(msg.sender, amount);
    }

    /// @notice The function setRate allows to define the rate. Currently the rate is 1 ETH per 1000 xSRO.
    /// @dev The receive function is public and only the owner can execute it.
    /// @param rate_ Rate.

    function setRate(uint256 rate_) public onlyOwner {
        require(rate_ > 0, "SwapSRO: rate cannot be 0");
        _rate = rate_;
        emit RateChanged(msg.sender, rate_);
    }

    /// @notice Check rate.
    /// @dev The rate function is public view.
    /// @return Rate.

    function rate() public view returns (uint256) {
        return _rate;
    }

    /// @notice Check price xSRO to ETH (coming soon).
    /// @dev The sroToEth function is public view.
    /// @return Price xSRO to ETH.
    
    function sroToEth(uint256 amount) public view returns (uint256) {
        return amount / _rate;
    }

    /// @notice Check price ETH to xSRO.
    /// @dev The ethToSro function is public view.
    /// @return Price ETH to xSRO.
    
    function ethToSro(uint256 amount) public view returns (uint256) {
        return amount * _rate;
    }

    /// @notice Check token address.
    /// @dev The token function is public view.
    /// @return Address of token.
    
    function token() public view returns (address) {
        return address(_token);
    }

    /// @notice Check token owner.
    /// @dev The tokenOwner function is public view.
    /// @return Address owner of token.
    
    function tokenOwner() public view returns (address) {
        return _tokenOwner;
    }

    /// @notice The owner of the total supply authorizes the swap of the smart-contract.
    /// @dev The ownerAllowance function is public view.
    /// @return How many tokens are allowed for this address.
  
    function ownerAllowance() public view returns (uint256) {
        //Todo Afficher les informations (combien il reste de xSRO à se procurer).
        return _token.allowance(_tokenOwner, address(this));
    }

    /// @notice The function _swapTokens allows to who does the swap with the number of ETH -> xSRO tokens, currently the rate is 1 ETH per 1000 xSRO.
    /// @dev The _swapTokens function is private.
    /// @param sender Sender's address.
    /// @param amount Amount.

    function _swapTokens(address sender, uint256 amount) private {
        // Todo "Require supplémentaire".
        uint256 tokenAmount = amount * _rate; 
        require(tokenAmount <= ownerAllowance(), "SwapSRO: you cannot swap more than the allowance"); 
        _token.transferFrom(_tokenOwner, sender, tokenAmount); 
        emit Swapped(sender, amount, tokenAmount);
    }
}
