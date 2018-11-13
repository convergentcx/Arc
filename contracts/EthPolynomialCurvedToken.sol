pragma solidity ^0.4.24;

import "./EthBondingCurveToken.sol";

contract EthPolynomialCurvedToken is EthBondingCurvedToken {

    uint256 public exponent;
    uint256 public inverseSlope;

    /// @dev constructor        Initializes the bonding curve
    /// @param name             The name of the token
    /// @param decimals         The number of decimals to use
    /// @param symbol           The symbol of the token
    /// @param _exponent        The exponent of the curve
    constructor(
        string name,
        string symbol,
        uint8 decimals,
        uint256 _exponent,
        uint256 _inverseSlope // Since we want the slope to be usually < 0 we take the inverse.
    ) EthBondingCurvedToken(name, symbol, decimals) public {
        exponent = _exponent;
        inverseSlope = _inverseSlope;
    }

    /// @dev        Calculate the integral from 0 to t
    /// @param t    The number to integrate to
    function curveIntegral(uint256 t) internal returns (uint256) {
        uint256 nexp = exponent.add(1);
        uint256 norm = 10 ** (uint256(decimals()) * uint256(nexp)) - 18;
        // Calculate integral of t^exponent
        return
            (t ** nexp).div(nexp).div(inverseSlope).div(10 ** 18);
    }

    function priceToMint(uint256 numTokens) public view returns(uint256) {
        return curveIntegral(totalSupply().add(numTokens)).sub(poolBalance);
    }

    function rewardForBurn(uint256 numTokens) public view returns(uint256) {
        return poolBalance.sub(curveIntegral(totalSupply().sub(numTokens)));
    }
}
