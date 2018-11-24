import { expect } from 'chai';
import { SpreadCBTInstance } from '../types/truffle-contracts';

import BN = require('bn.js');
import Web3 = require('web3');

import {
  addDecimals,
  removeDecimals,
} from './helpers';

declare const web3: Web3;

const SpreadCBT = artifacts.require('SpreadCBT');

contract('SpreadCBT', ([owner, user1, user2]) => {
  let spreadCBT: SpreadCBTInstance;

  before(async () => {
    spreadCBT = await SpreadCBT.new(
      'test token',
      'TEST',
      '18',
      '1',
      '1',
      '1200',
      '1000',
    );

    expect(spreadCBT.address).to.exist;

    const poolBalance = await spreadCBT.poolBalance();
    expect(poolBalance.toString()).to.equal('0');

    const buyExp = await spreadCBT.buyExp();
    expect(buyExp.toString()).to.equal('1');

    const sellExp = await spreadCBT.sellExp();
    expect(sellExp.toString()).to.equal('1');

    const buyInverseSlope = await spreadCBT.buyInverseSlope();
    expect(buyInverseSlope.toString()).to.equal('1000');

    const sellInverseSlope = await spreadCBT.sellInverseSlope();
    expect(sellInverseSlope.toString()).to.equal('1200');
  });

  it('Allows buying from the buy-curve', async () => {
    const price = await spreadCBT.priceToMint(addDecimals(50));
    const price2 = await spreadCBT.priceToMint(addDecimals(100));
    const price3 = await spreadCBT.priceToMint(addDecimals(150));
    const price4 = await spreadCBT.priceToMint(addDecimals(1000));

    // Expect that this is a linear curve, ie. each token bought makes
    // the next token one ether more expensive.
    expect(removeDecimals(price)).to.equal('1.25');
    expect(removeDecimals(price2)).to.equal('5');
    expect(removeDecimals(price3)).to.equal('11.25');
    expect(removeDecimals(price4)).to.equal('500');

    const gasPrice = 23;
    const buyTx: any = await spreadCBT.mint(addDecimals(50), {
      from: user1,
      value: web3.utils.toWei('1.25', 'ether'),
      gasPrice
    });

    const { status } = buyTx.receipt;
    expect(status).to.be.true;

    const poolBal = await spreadCBT.poolBalance();
    expect(removeDecimals(poolBal)).to.equal('1.25');
  });

  it('Allows selling into the sell-curve', async () => {
    const reward = await spreadCBT.rewardForBurn(addDecimals(10));
    const reward2 = await spreadCBT.rewardForBurn(addDecimals(25));
    const reward3 = await spreadCBT.rewardForBurn(addDecimals(50));

    const spread = await spreadCBT.spread();
    // console.log(removeDecimals(spread));

    // console.log(removeDecimals(reward))
    // console.log(removeDecimals(reward2))
    // console.log(removeDecimals(reward3))
  });

});
