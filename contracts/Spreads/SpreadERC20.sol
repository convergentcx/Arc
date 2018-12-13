pragma solidity ^0.4.24;

import "openzeppelin-eth/contracts/ownership/Ownable.sol";
import "zos-lib/contracts/Initializable.sol";

import "../Reserve/WithERC20Reserve.sol";

contract SpreadERC20 is WithERC20Reserve, Ownable, Initializable {

    uint256 public buyExponent;
    uint256 public sellExponent;

    uint256 public buyInverseSlope;
    uint256 public sellInverseSlope;

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

    function spread()
        public view returns (uint256)
    {
        uint256 buyIntegral = integral(
            totalSupply(),
            buyExp,
            buyInverseSlope
        );
        uint256 sellIntegral = integral(
            totalSupply(),
            sellExp,
            sellInverseSlope
        );
        return buyIntegral.sub(sellIntegral);
    }

    function priceToMint(uint256 numTokens)
        public view returns (uint256)
    {
        return integral(
            totalSupply.add(numTokens),
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
        _transfer(address(this), owner, spreadAfter.sub(spreadBefore));
    }

    function rewardForBurn(uint256 numTokens)
        public view returns (uint256)
    {
        return reserve.sub(integral(
            totalSupply().sub(numTokens),
            sellExponent,
            sellInverseSlope
        ));
    }
}
