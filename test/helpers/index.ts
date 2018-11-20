import Web3 = require('web3');

declare const web3: Web3;

export const addDecimals = (numTokens: any) => {
  return web3.utils.toWei(String(numTokens), 'ether').toString();
}

export const removeDecimals = (tokens: any) => {
  return web3.utils.fromWei(tokens, 'ether').toString();
}
