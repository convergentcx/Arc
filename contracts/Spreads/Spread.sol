pragma solidity ^0.4.24;

import "../Reserve/WithEtherReserve.sol";

contract Spread is WithEtherReserve {

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
    )   public
    {
        initialize(name, symbol, decimals);
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
        ).sub(reserve);
    }

    /// Overwrite
    function stake(uint256 newTokens)
        public payable returns (uint256 staked)
    {
        uint256 spreadBefore = spread(totalSupply());
        staked = super.stake(newTokens);

        uint256 spreadAfter = spread(totalSupply());
        address(this).transfer(spreadAfter.sub(spreadBefore));
    }

    function rewardForBurn(uint256 numTokens)
        public view returns (uint256)
    {
        return reserve.sub(integral(
            totalSupply().sub(numTokens),
            sellExp,
            sellInverseSlope
        ));
    }

    function spread(uint256 _at)
        public view returns (uint256)
    {
        uint256 buyIntegral = integral(
            _at,
            buyExp,
            buyInverseSlope
        );
        uint256 sellIntegral = integral(
            _at,
            sellExp,
            sellInverseSlope
        );
        return buyIntegral.sub(sellIntegral);
    }
}
