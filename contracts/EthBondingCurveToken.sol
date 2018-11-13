pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";


contract EthBondingCurvedToken is ERC20Detailed, ERC20 {
    using SafeMath for uint256;

    uint256 public poolBalance;

    event Minted(uint256 amount, uint256 totalCost);
    event Burned(uint256 amount, uint256 reward);

    constructor(
        string name,
        string symbol,
        uint8 decimals
    ) ERC20Detailed(name, symbol, decimals) public {}

    function priceToMint(uint256 numTokens) public view returns(uint256);

    function rewardForBurn(uint256 numTokens) public view returns(uint256);

    function mint(uint256 numTokens) public payable {
        uint256 priceForTokens = priceToMint(numTokens);
        require(msg.value >= priceForTokens);

        _mint(msg.sender, numTokens);
        poolBalance = poolBalance.add(priceForTokens);
        if (msg.value > priceForTokens) {
            msg.sender.transfer(msg.value - priceForTokens);
        }

        emit Minted(numTokens, priceForTokens);
    }

    function burn(uint256 numTokens) public {
        require(balanceOf(msg.sender) >= numTokens);

        uint256 ethToReturn = rewardForBurn(numTokens);
        _burn(msg.sender, numTokens);
        poolBalance = poolBalance.sub(ethToReturn);
        msg.sender.transfer(ethToReturn);

        emit Burned(numTokens, ethToReturn);
    }
}