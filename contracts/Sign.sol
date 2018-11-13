pragma solidity ^0.4.24;

import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract EthBondingCurvedToken is ERC20Detailed, ERC20 {
    using SafeMath for uint256;

    uint256 public poolBalance;

    event Minted(uint256 amount, uint256 totalCost);
    event Burned(uint256 amount, uint256 reward);

    constructor(
        string name,
        string symbol,
        uint8 decimals
    ) ERC20Detailed(name, symbol, decimals) public {}

    function priceToMint(uint256 numTokens) public view returns(uint256);

    function rewardForBurn(uint256 numTokens) public view returns(uint256);

    function mint(uint256 numTokens) public payable {
        uint256 priceForTokens = priceToMint(numTokens);
        require(msg.value >= priceForTokens);

        _mint(msg.sender, numTokens);
        poolBalance = poolBalance.add(priceForTokens);
        if (msg.value > priceForTokens) {
            msg.sender.transfer(msg.value - priceForTokens);
        }

        emit Minted(numTokens, priceForTokens);
    }

    function burn(uint256 numTokens) public {
        require(balanceOf(msg.sender) >= numTokens);

        uint256 ethToReturn = rewardForBurn(numTokens);
        _burn(msg.sender, numTokens);
        poolBalance = poolBalance.sub(ethToReturn);
        msg.sender.transfer(ethToReturn);

        emit Burned(numTokens, ethToReturn);
    }
}

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

contract Convergent_Billboard is Ownable, EthPolynomialCurvedToken {
    using SafeMath for uint256;

    uint256 cashed; // Amount of tokens that have been "cashed out."
    uint256 requiredAmt = 1 * 10**18; // One token per banner change.

    event Advertisement(bytes32 what, uint256 indexed when);

    constructor()
        EthPolynomialCurvedToken(
            "Convergent Billboard",
            "CVRGNT_BILL",
            18,
            1,
            1000
        ) public
    {}
    
    function purchaseAdvertisement(bytes32 _what) public payable {
        mint(requiredAmt);
        submit(_what);
    }

    function submit(bytes32 _what)
        public
    {
        require(balanceOf(msg.sender) >= requiredAmt);

        cashed++; // increment cashed counter
        _transfer(msg.sender, address(0x1337), requiredAmt);

        uint256 dec = 10**uint256(decimals());
        uint256 newCliff = curveIntegral(
            (cashed).mul(dec)
        );
        uint256 oldCliff = curveIntegral(
            (cashed - 1).mul(dec)
        );
        uint256 cliffDiff = newCliff.sub(oldCliff);
        owner().transfer(cliffDiff);

        emit Advertisement(_what, block.timestamp);
    }
}
