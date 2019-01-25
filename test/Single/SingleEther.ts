import { expect } from 'chai';
// import { SingleEtherInstance } from '../../types/truffle-contracts';

import BN = require('bn.js');
import Web3 = require('web3');

import { findEvent } from '../helpers';

declare const web3: Web3;
const { fromWei, toBN, toWei } = web3.utils;

const SingleEther = artifacts.require('SingleEther');

// Environmental variable is set to `true` if run as `yarn test:gasreport`.
const GAS_REPORTING = !!process.env.GAS_REPORTING;
const gasReport: any = {};

contract('SingleEther', ([owner, user1, user2]) => {
  let singleEther: any;

  before(async () => {
    singleEther = await SingleEther.new();
    await singleEther.initialize(
      "Logan Coin",
      "LOGAN",
      18,
      1,
      1000,
    );
  });

  it('Sanity checks', async () => {
    const name = await singleEther.name();
    expect(name).to.equal("Logan Coin");

    const symbol = await singleEther.symbol();
    expect(symbol).to.equal("LOGAN");

    const decimals = await singleEther.decimals();
    expect(decimals.toString()).to.equal("18");

    const exponent = await singleEther.exponent();
    expect(exponent.toString()).to.equal("1");

    const inverseSlope = await singleEther.inverseSlope();
    expect(inverseSlope.toString()).to.equal("1000");
  });

  it('Allows for buy()', async () => {
    const amountToBuy = toWei('.73', 'ether');
    const priceToBuy = await singleEther.price(amountToBuy);

    const buyTx = await singleEther.buy(
      amountToBuy,
      {
        from: user1,
        value: priceToBuy.toString(),
      },
    );

    if (GAS_REPORTING) { gasReport['buyTx'] = buyTx.receipt.gasUsed; };

    expect(buyTx.receipt).to.exist;

    const buyEvent = findEvent(buyTx.logs, "CurveBuy");
    expect(buyEvent).to.exist;

    expect(buyEvent.args.amount.toString()).to.equal(amountToBuy);
    expect(fromWei(buyEvent.args.paid.toString())).to.equal('0.00026645');
  
    const tokenBalance = await singleEther.balanceOf(user1);
    expect(tokenBalance.toString()).to.equal(amountToBuy);
  });

  it('Allows for sell()', async () => {
    // Ensure tests run in sync.
    const tokenBalance = await singleEther.balanceOf(user1);
    expect(tokenBalance.toString()).to.equal(toWei('0.73', 'ether'));

    // Constans from last test.
    const expectedReserve: BN = toBN(toWei('0.00026645'));

    const contractBal = await web3.eth.getBalance(singleEther.address);
    expect(contractBal.toString()).to.equal(expectedReserve.toString());

    const reserve = await singleEther.reserve();
    expect(reserve.toString()).to.equal(expectedReserve.toString());

    const sellTx = await singleEther.sell(
      tokenBalance.toString(),
      {
        from: user1,
      },
    );

    if (GAS_REPORTING) { gasReport['sellTx'] = sellTx.receipt.gasUsed; };

    expect(sellTx.receipt).to.exist;

    const sellEvent = findEvent(sellTx.logs, 'CurveSell');
    expect(sellEvent).to.exist;

    expect(sellEvent.args.amount.toString()).to.equal(tokenBalance.toString());
    expect(sellEvent.args.rewarded.toString()).to.equal(expectedReserve.toString());

    const newBalance = await singleEther.balanceOf(user1);
    expect(newBalance.toString()).to.equal('0');

    const newReserve = await singleEther.reserve();
    expect(newReserve.toString()).to.equal('0');

    const bcBalance = await web3.eth.getBalance(singleEther.address);
    expect(bcBalance.toString()).to.equal('0');
  });

  after(() => {
    if (GAS_REPORTING) {
      Object.keys(gasReport).forEach((key: string) => {
        console.log(key.toUpperCase());
        console.log('-'.repeat(32));
        console.log(gasReport[key] + '\n');
      });
    };
  });
});
