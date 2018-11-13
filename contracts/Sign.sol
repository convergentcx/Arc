pragma solidity 0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

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

    uint8 public exponent;
    uint256 public slope;

    /// @dev constructor        Initializes the bonding curve
    /// @param name             The name of the token
    /// @param decimals         The number of decimals to use
    /// @param symbol           The symbol of the token
    /// @param _exponent        The exponent of the curve
    constructor(
        string name,
        string symbol,
        uint8 decimals,
        uint8 _exponent,
        uint256 _slope
    ) EthBondingCurvedToken(name, symbol, decimals) public {
        exponent = _exponent;
        slope = _slope;
    }

    /// @dev        Calculate the integral from 0 to t
    /// @param t    The number to integrate to
    function curveIntegral(uint256 t) internal returns (uint256) {
        uint256 nexp = exponent + 1;
        // Calculate integral of t^exponent
        return ((t ** nexp).div(nexp).div(slope)).div(10 ** uint256(decimals()));
    }

    function priceToMint(uint256 numTokens) public view returns(uint256) {
        return curveIntegral(totalSupply().add(numTokens)).sub(poolBalance);
    }

    function rewardForBurn(uint256 numTokens) public view returns(uint256) {
        return poolBalance.sub(curveIntegral(totalSupply().sub(numTokens)));
    }

    uint256 public adminBurned;

    function adminBurn(uint256 numTokens) public returns (bool) {
        require(balanceOf(msg.sender) > numTokens, "Must have sufficient amount of token to perform `adminBurn()`");
        uint256 newAdminBurned = adminBurned.add(numTokens);
        uint256 cliff = curveIntegral(newAdminBurned.sub(adminBurned));
        msg.sender.transfer(cliff);
        adminBurned = newAdminBurned;
        return true;
    }
}

contract Sign {
    address public owner;
    bytes32 public sign;
    address public token;

    event SignChanged(bytes32 newSign);

    constructor(address _token) public {
        owner = msg.sender;
        token = _token;
    }

    function changeSign(bytes32 _sign)
        public returns (bool)
    {   
        ERC20(token).transferFrom(msg.sender, owner, 1);
        sign = _sign;
        emit SignChanged(sign);
    }
}
