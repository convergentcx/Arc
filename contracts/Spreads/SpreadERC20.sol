pragma solidity ^0.4.24;

import "openzeppelin-eth/contracts/ownership/Ownable.sol";
import "zos-lib/contracts/Initializable.sol";

import "../Reserve/WithERC20Reserve.sol";

contract SpreadERC20 is Initializable, Ownable, WithERC20Reserve {

    uint256 public buyExponent;
    uint256 public sellExponent;

    uint256 public buyInverseSlope;
    uint256 public sellInverseSlope;

    event SpreadPayout(uint256 amount);

    function initialize(
        string name,
        string symbol,
        uint8 decimals,
        address _reserveToken,
        uint256 _buyExponent,
        uint256 _sellExponent,
        uint256 _buyInverseSlope,
        uint256 _sellInverseSlope
    )   initializer   
        public
    {
        WithERC20Reserve.initialize(name, symbol, decimals, _reserveToken);
        Ownable.initialize(msg.sender);
        buyExponent = _buyExponent;
        sellExponent = _sellExponent;
        buyInverseSlope = _buyInverseSlope;
        sellInverseSlope = _sellInverseSlope;
    } 

    function integral(
        uint256 _d,
        uint256 _exponent,
        uint256 _inverseSlope
    )   internal view returns (uint256) {
        uint256 nexp = _exponent.add(1);
        return (_d ** nexp).div(nexp).div(_inverseSlope).div(10**18);
    }

    function spread(uint256 _x)
        public view returns (uint256)
    {
        uint256 buyIntegral = integral(
            _x,
            buyExponent,
            buyInverseSlope
        );
        uint256 sellIntegral = integral(
            _x,
            sellExponent,
            sellInverseSlope
        );
        return buyIntegral.sub(sellIntegral);
    }

    function stakeAmt(uint256 numTokens)
        public view returns (uint256)
    {
        return integral(
            totalSupply().add(numTokens),
            buyExponent,
            buyInverseSlope
        ).sub(reserve);
    }

    /// Overwrite
    function stake(uint256 newTokens)
        public returns (uint256 staked)
    {
        uint256 spreadBefore = spread(totalSupply());
        staked = super.stake(newTokens);

        uint256 spreadAfter = spread(totalSupply());
        uint256 spreadPayout = spreadAfter.sub(spreadBefore);
        reserve = reserve.sub(spreadPayout);
        reserveToken.transfer(owner(), spreadPayout);
        emit SpreadPayout(spreadPayout);
    }

    function withdrawAmt(uint256 numTokens)
        public view returns (uint256)
    {
        return reserve.sub(integral(
            totalSupply().sub(numTokens),
            sellExponent,
            sellInverseSlope
        ));
    }
}
