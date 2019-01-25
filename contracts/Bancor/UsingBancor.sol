pragma solidity ^0.4.24;

import "openzeppelin-eth/contracts/math/SafeMath.sol";
import "openzeppelin-eth/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-eth/contracts/token/ERC20/ERC20Detailed.sol";
import "zos-lib/contracts/Initializable.sol";

import "./BancorFormula.sol";

contract UsingBancor is Initializable, ERC20, ERC20Detailed, BancorFormula {
    using SafeMath for uint256;

    address public reserveAsset;
    uint256 public reserve;
    uint32 public reserveRatio;

    function initialize(string name, string symbol, uint8 decimals, uint32 _reserveRatio)
        initializer public
    {
        ERC20Detailed.initialize(name, symbol, decimals);
        reserveRatio = _reserveRatio;
        _mint(msg.sender, 10 * 10 ** uint256(decimals));
    }

    function addReserve(uint256 howMuch)
        payable public
    {
        require(howMuch == msg.value);
        reserve = reserve.add(howMuch);
    }

    function buy(uint256 amountToPay)
        public payable returns (uint256 newTokens)
    {
        if (reserveAsset == address(0x0)) {
            require(msg.value >= amountToPay);
            newTokens = calculatePurchaseReturn(totalSupply(), reserve, reserveRatio, amountToPay);

            reserve = reserve.add(amountToPay);
            _mint(msg.sender, newTokens);

            if (msg.value > amountToPay) {
                msg.sender.transfer(msg.value.sub(amountToPay));
            }

            emit CurveBuy(newTokens, amountToPay, msg.sender);
        }
    }

    function sell(uint256 tokens)
        public returns (uint256 rewarded)
    {
        require(tokens > 0);
        require(balanceOf(msg.sender) >= tokens);

        rewarded = calculateSaleReturn(totalSupply(), reserve, reserveRatio, tokens);
        
        reserve = reserve.sub(rewarded);
        _burn(msg.sender, tokens);
        msg.sender.transfer(rewarded);

        emit CurveSell(tokens, rewarded, msg.sender);
    }

    event CurveBuy(uint256 amount, uint256 paid, uint256 indexed buyer);
    event CurveSell(uint256 amount, uint256 rewarded, uint256 indexed seller);
}
