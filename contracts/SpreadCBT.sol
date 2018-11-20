pragma solidity ^0.4.24;

import "./EthBondingCurveToken.sol";

contract SpreadCBT is EthBondingCurvedToken {

    uint256 public buyExp;  // Buy exponent
    uint256 public sellExp; // Sell exponent

    uint256 public buyInverseSlope;
    uint256 public sellInverseSlope;

    constructor(
        string name,
        string symbol,
        uint8 decimals,
        uint256 _se,
        uint256 _be,
        uint256 _sis,
        uint256 _bis
    )   EthBondingCurvedToken(name, symbol, decimals)
        public
    {
        buyExp = _be;
        sellExp = _se;
        require(_bis <= _sis, "Must exist a higher buy curve than a sell curve.");
        buyInverseSlope = _bis;
        sellInverseSlope = _sis;
    }

    function integral(
        uint256 _t,
        uint256 _exp,
        uint256 _inverseSlope
    )   internal view returns (uint256) {
        uint256 nexp = _exp.add(1);
        return (_t ** nexp).div(nexp).div(_inverseSlope).div(10**18);
    }

    function priceToMint(uint256 numTokens)
        public view returns (uint256)
    {
        return integral(
            totalSupply().add(numTokens),
            buyExp,
            buyInverseSlope
        ).sub(poolBalance);
    }

    function rewardForBurn(uint256 numTokens)
        public view returns (uint256)
    {
        return poolBalance.sub(integral(
            totalSupply().sub(numTokens),
            sellExp,
            sellInverseSlope
        ));
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
}
