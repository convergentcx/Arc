pragma solidity ^0.4.24;

import "openzeppelin-eth/contracts/token/ERC20/ERC20Detailed.sol";

import "./SimpleCBT.sol";

contract SimpleCBTDetailed is SimpleCBT, ERC20Detailed {
    constructor(
        string name,
        string symbol,
        uint256 reserveRatio
    )   public
        SimpleCBT(reserveRatio)
    {
        initialize(name, symbol, 18);
    }
}
