// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
// Import XSRO ou ERC20 ???????
import "./xSRO.sol";

contract SwapSRO is Ownable {
    using Address for address payable;

    // variable state
    SarahRO private _token; // transfert token 
    address private _tokenOwner; // besoin de savoir qui pocede la total suplly
    uint256 private _rate; // Taux conversion
    
    // Event
    event Swapped(address indexed swapper, uint256 ethAmount, uint256 sroAmount); // Event swap qui a echanger cb de eth / Sro 
    event Withdrew(address indexed owner, uint256 amount); // le owner du contrat peu récuperer la balance du SC swap 
    event RateChanged(address indexed owner, uint256 newRate); // Si rate change action (coming soon) -> Todo: recupère sur front (current)

    // adresse du XSRO + adress total supply
    constructor(address xsroAddress, address tokenOwner_) {
        // require (token owner = all xsro)
        _token = SarahRO(xsroAddress);
        _tokenOwner = tokenOwner_;
        _rate = 1000;
    }

    // fnt receive pour (ETH) si on envoi des ETH à cette adresse (Metamask) -> Utilisateur
    receive() external payable {
        _swapTokens(msg.sender, msg.value);
    }

    // fn bouton swap front (swap token)
    function swapTokens() public payable {
        _swapTokens(msg.sender, msg.value);
    }

    // fn Recup ETH que les utilisateur auront swap
    function withdrawAll() public onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "SwapSRO: nothing to withdraw");
        payable(msg.sender).sendValue(amount);
        emit Withdrew(msg.sender, amount);
    }

    // Setup Rate seulement par le Owner du SC
    function setRate(uint256 rate_) public onlyOwner {
        require(rate_ > 0, "SwapSRO: rate cannot be 0");
        _rate = rate_;
        emit RateChanged(msg.sender, rate_);
    }

    // voir rate
    function rate() public view returns (uint256) {
        return _rate;
    }
    // Voir le prix SRO / ETH (coming soon)
    function sroToEth(uint256 amount) public view returns (uint256) {
        return amount / _rate;
    }

    // Voir le prix ETH / SRO
    function ethToSro(uint256 amount) public view returns (uint256) {
        return amount * _rate;
    }

    // adresse Token 
    function token() public view returns (address) {
        return address(_token);
    }

    // Token owner
    function tokenOwner() public view returns (address) {
        return _tokenOwner;
    }

    //Allowance <-> Celui qui pocede la total supply autorise le swap du SC (Transfert from)
    function ownerAllowance() public view returns (uint256) {
        // afficher les informations (combien il reste de SRO à se procurer)
        return _token.allowance(_tokenOwner, address(this));
    }

    // Qui fait le swap avec le nombre de token ETH -> SRO 
    function _swapTokens(address sender, uint256 amount) private {
        // require
        uint256 tokenAmount = amount * _rate; // 1 * rate (1000 SRO) = tokenAmount
        require(tokenAmount <= ownerAllowance(), "SwapSRO: you cannot swap more than the allowance"); 
        _token.transferFrom(_tokenOwner, sender, tokenAmount); // Tr Total supply vers User
        emit Swapped(sender, amount, tokenAmount); // Event
    }
}
