import { expect } from 'chai';
import { SpreadCBTInstance } from '../types/truffle-contracts';

import BN = require('bn.js');
import Web3 = require('web3');

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
      '500',
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
    expect(sellInverseSlope.toString()).to.equal('500');
  });

  it('tests', () => {});
})