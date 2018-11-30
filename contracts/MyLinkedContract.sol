pragma solidity ^0.4.24;

import "openzeppelin-eth/contracts/token/ERC721/ERC721Mintable.sol";

contract MyLinkedContract {
  ERC721Mintable private _token;

  function setToken(ERC721Mintable token) external {
    require(token != address(0));
    _token = token;
  }
}
