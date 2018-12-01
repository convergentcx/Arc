pragma solidity ^0.4.24;

import "./Reserve/WithEtherReserve.sol";

contract Polynomial is WithEtherReserve {

    uint256 public exponent;
    uint256 public inverseSlope;

    constructor(
        string name,
        string symbol,
        uint8 decimals,
        uint256 _exponent,
        uint256 _inverseSlope
    )   
        public
    {
        initialize(name, symbol, decimals);
        exponent = _exponent;
        inverseSlope = _inverseSlope;
    }

    function curveIntegral(uint256 t) internal returns (uint256) {
        uint256 nexp = exponent.add(1);
        uint256 norm = 10 ** (uint256(decimals()) * uint256(nexp)) - 18;
        // Calculate integral of t^exponent
        return
            (t ** nexp).div(nexp).div(inverseSlope).div(10 ** 18);
    }

    function priceToMint(uint256 numTokens) public view returns(uint256) {
        return curveIntegral(totalSupply().add(numTokens)).sub(reserve);
    }

    function rewardForBurn(uint256 numTokens) public view returns(uint256) {
        return reserve.sub(curveIntegral(totalSupply().sub(numTokens)));
    }
}
