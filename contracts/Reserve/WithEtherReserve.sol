pragma solidity ^0.4.24;

import "openzeppelin-eth/contracts/math/SafeMath.sol";
import "openzeppelin-eth/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-eth/contracts/token/ERC20/ERC20Detailed.sol";
import "zos-lib/contracts/Initializable.sol";


contract WithEtherReserve is Initializable, ERC20, ERC20Detailed {
    using SafeMath for uint256;

    uint256 public reserve;

    event CurveBuy(uint256 amount, uint256 paid, uint256 indexed when);
    event CurveSell(uint256 amount, uint256 rewarded, uint256 indexed when);

    function initialize(string name, string symbol, uint8 decimals)
        initializer
        public
    {
        ERC20Detailed.initialize(name, symbol, decimals);
    }

    /**
     * Curve function interfaces */

    function price(uint256 tokens) public view returns (uint256 thePrice);
    function reward(uint256 tokens) public view returns (uint256 theReward);

    /**
     * stake and withdraw */

    function buy(uint256 tokens)
        public payable returns (uint256 paid)
    {
        require(tokens > 0, "Must request non-zero amount of tokens.");

        paid = price(tokens);
        require(
            msg.value >= paid,
            "Did not send enough ether to buy!"
        );

        reserve = reserve.add(paid);
        _mint(msg.sender, tokens);
        // extra funds handling
        if (msg.value > paid) {
            msg.sender.transfer(msg.value.sub(paid));
        }

        emit CurveBuy(tokens, paid, block.timestamp);
    } 
    
    function sell(uint256 tokens)
        public returns (uint256 rewarded)
    {
        require(tokens > 0, "Must spend non-zero amount of tokens.");
        require(
            balanceOf(msg.sender) >= tokens,
            "Sender does not have enough tokens to spend."
        );

        rewarded = reward(tokens);
        reserve = reserve.sub(rewarded);
        _burn(msg.sender, tokens);
        msg.sender.transfer(rewarded);

        emit CurveSell(tokens, rewarded, block.timestamp);
    }
}
