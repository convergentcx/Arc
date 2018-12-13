import { expect } from 'chai';
import { MockERC20Instance, SpreadERC20Instance } from '../../types/truffle-contracts';

import BN = require('bn.js');
import Web3 = require('web3');

declare const web3: Web3;

const MockERC20 = artifacts.require('MockERC20');
const SpreadERC20 = artifacts.require('SpreadERC20');

contract('SpreadERC20', ([owner, user1, user2]) => {
  let mockERC20: MockERC20Instance;
  let spreadERC20: any;

  before(async () => {
    mockERC20 = await MockERC20.new();
    await mockERC20.initialize(
      "Mock Token",
      "MOCK",
      18,
    );

    expect(mockERC20.address).to.exist;

    spreadERC20 = await SpreadERC20.new();
    spreadERC20.initialize(
      "Logan Coin",
      "LOGAN",
      18,
      mockERC20.address,
      1,
      1,
      1000,
      1200,
    );
  });

  it('Sanity checks', async () => {
    const name = await spreadERC20.name();
    expect(name).to.equal("Logan Coin");

    const symbol = await spreadERC20.symbol();
    expect(symbol).to.equal("LOGAN");

    const decimals = await spreadERC20.decimals();
    expect(decimals.toNumber()).to.equal(18);

    const buyExponent = await spreadERC20.buyExponent();
    expect(buyExponent.toNumber()).to.equal(1);

    const sellExponent = await spreadERC20.sellExponent();
    expect(sellExponent.toNumber()).to.equal(1);

    const buyInverseSlope = await spreadERC20.buyInverseSlope();
    expect(buyInverseSlope.toNumber()).to.equal(1000);

    const sellInverseSlope = await spreadERC20.sellInverseSlope();
    expect(sellInverseSlope.toNumber()).to.equal(1200);
  });

  it('Allows for stake()', async () => {
    mockERC20.mint(user1, web3.utils.toWei('20', 'ether'));
    expect(
      (await mockERC20.balanceOf(user1)).toString()
    ).to.equal(web3.utils.toWei('20', 'ether'));

    const stakeTx = await spreadERC20.stake(
      web3.utils.toWei('1', 'ether'),
      {
        from: user1,
      }
    );

    const findEvent = (logs: any, event: string) => {
      return logs.find((log: any) => log.event === event);
    }

    const found = findEvent(stakeTx.logs, "CurveStake");
    expect(found).to.exist;

    expect(found.args.newTokens.toString()).to.equal(web3.utils.toWei('1', 'ether'));

  })
})