pragma solidity ^0.4.24;

import "openzeppelin-eth/contracts/ownership/Ownable.sol";
import "zos-lib/contracts/Initializable.sol";

import "../Reserve/WithEtherReserve.sol";

contract SpreadEther is Initializable, Ownable, WithEtherReserve {

    uint256 public buyExponent;
    uint256 public sellExponent;

    uint256 public buyInverseSlope;
    uint256 public sellInverseSlope;

    event Payout(uint256 payout, uint256 indexed timestamp);

    function initialize(
        string name,
        string symbol,
        uint8 decimals,
        uint256 _buyExponent,
        uint256 _sellExponent,
        uint256 _buyInverseSlope,
        uint256 _sellInverseSlope
    )   initializer
        public
    {
        Ownable.initialize(msg.sender);
        WithEtherReserve.initialize(name, symbol, decimals);
        buyExponent = _buyExponent;
        sellExponent = _sellExponent;
        buyInverseSlope = _buyInverseSlope;
        sellInverseSlope = _sellInverseSlope;
    }

    function integral(
        uint256 toX,
        uint256 exponent,
        uint256 inverseSlope
    )   internal pure returns (uint256) {
        uint256 nexp = exponent.add(1);
        return (toX ** nexp).div(nexp).div(inverseSlope).div(10**18);
    }

    function spread(uint256 toX)
        public view returns (uint256)
    {
        uint256 buyIntegral = integral(toX, buyExponent, buyInverseSlope);
        uint256 sellIntegral = integral(toX, sellExponent, sellInverseSlope);
        return buyIntegral.sub(sellIntegral);
    }

    function price(uint256 tokens)
        public view returns (uint256)
    {
        return integral(
            totalSupply().add(tokens),
            buyExponent,
            buyInverseSlope
        ).sub(reserve);
    }

    /// Overwrite
    function buy(uint256 tokens)
        public payable returns (uint256 paid)
    {
        uint256 spreadBefore = spread(totalSupply());
        paid = super.buy(tokens);
        uint256 spreadAfter = spread(totalSupply());

        uint256 spreadPayout = spreadAfter.sub(spreadBefore);
        reserve = reserve.sub(spreadPayout);
        owner().transfer(spreadPayout);
        emit Payout(spreadPayout, block.timestamp);
    }

    function reward(uint256 tokens)
        public view returns (uint256)
    {
        return reserve.sub(integral(
            totalSupply().sub(tokens),
            sellExponent,
            sellInverseSlope
        ));
    }
}
