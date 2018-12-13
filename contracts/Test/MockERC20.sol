pragma solidity ^0.4.24;

import "openzeppelin-eth/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-eth/contracts/token/ERC20/ERC20Detailed.sol";
import "zos-lib/contracts/Initializable.sol";

contract MockERC20 is Initializable, ERC20, ERC20Detailed {
    function initialize(
        string name,
        string symbol,
        uint8 decimals
    )   public
    {
        ERC20Detailed.initialize(name, symbol, decimals);
    }

    function mint(address to, uint256 amount)
        public returns (bool)
    {
        _mint(to, amount);
        return true;
    }
}
