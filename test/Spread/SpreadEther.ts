import { expect } from 'chai';
import { SpreadEtherInstance } from '../../types/truffle-contracts';

import BN = require('bn.js');
import Web3 = require('web3');

import { findEvent } from '../helpers';

declare const web3: Web3;
const { fromWei, toBN, toWei } = web3.utils;

const SpreadEther = artifacts.require('SpreadEther');

contract('SpreadEther', ([owner, user1, user2]) => {
  let spreadEther: any;

  before(async () => {
    spreadEther = await SpreadEther.new();
    await spreadEther.initialize(
      "Test Spread Coin",
      "TSC",
      18,
      1,
      1,
      3000,
      4000,
    );

    expect(spreadEther.address).to.exist;
  });

  it('Sanity checks', async () => {
    const name = await spreadEther.name();
    expect(name).to.equal("Test Spread Coin");

    const symbol = await spreadEther.symbol();
    expect(symbol).to.equal("TSC");

    const decimals = await spreadEther.decimals();
    expect(decimals.toNumber()).to.equal(18);

    const buyExponent = await spreadEther.buyExponent();
    expect(buyExponent.toNumber()).to.equal(1);

    const sellExponent = await spreadEther.sellExponent();
    expect(sellExponent.toNumber()).to.equal(1);

    const buyInverseSlope = await spreadEther.buyInverseSlope();
    expect(buyInverseSlope.toNumber()).to.equal(3000);

    const sellInverseSlope = await spreadEther.sellInverseSlope();
    expect(sellInverseSlope.toNumber()).to.equal(4000);
  });

  it('Allows for buy()', async () => {
    const amountToBuy = toWei('1.5', 'ether');
    const priceToBuy = await spreadEther.price(amountToBuy);

    const ownerBalanceBefore: BN = toBN(await web3.eth.getBalance(owner));

    const buyTx = await spreadEther.buy(
      amountToBuy,
      {
        from: user1,
        value: priceToBuy.toString(),
      },
    );

    expect(buyTx.receipt).to.exist;

    const buyEvent = findEvent(buyTx.logs, "CurveBuy");
    expect(buyEvent).to.exist;

    expect(buyEvent.args.amount.toString()).to.equal(amountToBuy);
    expect(fromWei(buyEvent.args.paid.toString())).to.equal('0.000375');

    const payoutEvent = findEvent(buyTx.logs, "Payout");
    expect(payoutEvent).to.exist;

    expect(fromWei(payoutEvent.args.payout.toString())).to.equal('0.00009375');

    // Check payout went to the owner.
    const theOwner = await spreadEther.owner();
    expect(theOwner).to.equal(owner);

    const ownerBalanceAfter: BN = toBN(await web3.eth.getBalance(owner));
    expect(ownerBalanceAfter.sub(ownerBalanceBefore).toString()).to.equal(payoutEvent.args.payout.toString());

    const tokenBalance = await spreadEther.balanceOf(user1);
    expect(tokenBalance.toString()).to.equal(amountToBuy);
  });

  it('Allows for sell()', async () => {
    // We check this again to make sure tests run in sync.
    const tokenBalance = await spreadEther.balanceOf(user1);
    expect(tokenBalance.toString()).to.equal(toWei('1.5', 'ether'));

    // Constants from last test.
    const paid: BN = toBN(toWei('0.000375'));
    const payout: BN = toBN(toWei('0.00009375'));
    const expectedReserve: BN = paid.sub(payout);

    const contractBal = await web3.eth.getBalance(spreadEther.address);
    expect(contractBal.toString()).to.equal(expectedReserve.toString());

    const reserve = await spreadEther.reserve();
    expect(reserve.toString()).to.equal(expectedReserve.toString());

    const sellTx = await spreadEther.sell(
      tokenBalance.toString(),
      {
        from: user1,
      },
    );

    expect(sellTx.receipt).to.exist;

    const sellEvent = findEvent(sellTx.logs, "CurveSell");
    expect(sellEvent).to.exist;

    expect(sellEvent.args.amount.toString()).to.equal(tokenBalance.toString());
    expect(sellEvent.args.rewarded.toString()).to.equal(expectedReserve.toString());

    // Check user1 balance of token === 0.
    const newBalance = await spreadEther.balanceOf(user1);
    expect(newBalance.toString()).to.equal('0');

    // Check bonding curve reserve === 0 && ether balance === 0.
    const newReserve = await spreadEther.reserve();
    expect(newReserve.toString()).to.equal('0');

    const bcBalance = await web3.eth.getBalance(spreadEther.address);
    expect(bcBalance.toString()).to.equal('0');
  });
});
