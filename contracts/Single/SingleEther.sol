pragma solidity ^0.4.24;

import "openzeppelin-eth/contracts/ownership/Ownable.sol";
import "zos-lib/contracts/Initializable.sol";

import "../Reserve/WithEtherReserve.sol";

contract SingleEther is Initializable, Ownable, WithEtherReserve {

    uint256 public exponent;
    uint256 public inverseSlope;

    function initialize(
        string name,
        string symbol,
        uint8 decimals,
        uint256 _exponent,
        uint256 _inverseSlope
    )   initializer
        public
    {
        Ownable.initialize(msg.sender);
        WithEtherReserve.initialize(name, symbol, decimals);
        exponent = _exponent;
        inverseSlope = _inverseSlope;
    }

    function integral(uint256 toX, uint256 _exponent, uint256 _inverseSlope)
        internal pure returns (uint256)
    {
        uint256 nexp = _exponent.add(1);
        return (toX ** nexp).div(nexp).div(_inverseSlope).div(10**18);
    }

    function price(uint256 forTokens)
        public view returns (uint256 thePrice)
    {
        return integral(totalSupply().add(forTokens), exponent, inverseSlope).sub(reserve);
    }

    function reward(uint256 forTokens)
        public view returns (uint256 theReward)
    {
        return reserve.sub(integral(totalSupply().sub(forTokens), exponent, inverseSlope));
    }

    function currentPrice()
        public view returns (uint256 theCurrentPrice)
    {
        return (totalSupply() ** exponent).div(inverseSlope).div(10**18);
    }
}
