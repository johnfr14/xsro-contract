// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Create xSRO Token (xSRO).
/// @author Team SarahRo (SRO).
/// @notice Token is a basic ERC20.

// Todo changer le nom du contrat.

contract SarahRO is ERC20 {
    constructor() ERC20("xSarahRO", "xSRO") {
        _mint(msg.sender, 10000000 * 10**decimals());
    }
}
