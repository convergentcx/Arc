pragma solidity ^0.4.24;

import "openzeppelin-eth/contracts/math/SafeMath.sol";
import "openzeppelin-eth/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-eth/contracts/token/ERC20/ERC20Detailed.sol";
import "zos-lib/contracts/Initializable.sol";

contract WithERC20Reserve is Initializable, ERC20, ERC20Detailed {
    using SafeMath for uint256;

    ERC20 public reserveToken;
    uint256 public reserve;

    event CurveStake(uint256 newTokens, uint256 nStaked, uint256 indexed when);
    event CurveWithdraw(uint256 spentTokens, uint256 nWithdrawn, uint256 indexed when);

    function initialize(string name, string symbol, uint8 decimals, address _reserveToken)
        initializer
        public
    {
        ERC20Detailed.initialize(name, symbol, decimals);
        reserveToken = ERC20(_reserveToken);
    }

    /**
     * curve function interfaces */

    function stakeAmt(uint256 newTokens) public view returns (uint256);
    function withdrawAmt(uint256 spendTokens) public view returns (uint256);

    /**
     * stake and withdraw */
    
    function stake(uint256 newTokens)
        public returns (uint256 staked)
    {
        require(newTokens > 0, "Must request non-zero amount of new tokens.");

        staked = stakeAmt(newTokens);
        require(
            reserveToken.balanceOf(msg.sender) >= staked,
            "Sender does not have enough reserve tokens to stake!"
        );

        reserveToken.transferFrom(msg.sender, address(this), staked);
        reserve = reserve.add(staked);
        _mint(msg.sender, newTokens);

        emit CurveStake(newTokens, staked, block.timestamp);
    }

    function withdraw(uint256 spendTokens)
        public returns (uint256 withdrawn)
    {
        require(spendTokens > 0, "Must spend non-zero amount of tokens.");
        require(
            balanceOf(msg.sender) >= spendTokens,
            "Sender does not have enough tokens to spend."
        );

        withdrawn = withdrawAmt(spendTokens);
        reserve = reserve.sub(withdrawn);        
        _burn(msg.sender, spendTokens);
        reserveToken.transfer(msg.sender, withdrawn);

        emit CurveWithdraw(spendTokens, withdrawn, block.timestamp);
    }
}
