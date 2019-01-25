pragma solidity ^0.4.24;

/**
 * @title Bonded Fungible Token Interface
 * @dev A bonded fungible token is a token "bonded" to a reserve asset and
 *      continuously generated or destroyed by staking or withdrawing this
 *      asset.
 */
interface IBondedFungibleToken {

    // Logs when `purchaser` buys `amount` of tokens for `paid` in reserve asset.
    event CurveBuy(uint256 amount, uint256 paid, address indexed purchaser);

    // Logs when `seller` sells `amount` of tokens for `rewarded` in reserve asset.
    event CurveSell(uint256 amount, uint256 rewarded, address indexed seller);

    // Returns the price for buying `forTokens` amount of bonded tokens.
    function price(uint256 forTokens) external view returns (uint256 thePrice);

    // Returns the reward for selling `forTokens` amount of bonded tokens.
    function reward(uint256 forTokens) external view returns (uint256 theReward);

    // Buys `tokens` amount of bonded tokens and returns how much `paid` in reserve.
    function buy(uint256 tokens) external returns (uint256 paid);

    // Sells `tokens` amount of bonded tokens and returns how much `rewarded` in reserve.
    function sell(uint256 tokens) external returns (uint256 rewarded);

    // Returns the current price of the token. Mostly useful for reference.
    function currentPrice() external view returns (uint256 theCurrentPrice);

    // Returns the address of the asset smart contract or 0x0 for ether.
    function reserveAsset() external view returns (address asset);

    // Returns the amount of `reserveAsset` held in reserve in contract. 
    function reserve() external view returns (uint256 amount);
}
