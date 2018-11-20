import { expect } from 'chai';
import { EthPolynomialCurvedTokenInstance } from '../types/truffle-contracts';

import BN = require('bn.js');
import Web3 = require('web3');

import {
  addDecimals,
  removeDecimals,
} from './helpers';

declare const web3: Web3;

const EthPolynomialCurvedToken = artifacts.require('EthPolynomialCurvedToken');

contract('EthPolynomialCurvedTokenLinear', ([owner, user1, user2]) => {
  let ethCurvedToken: EthPolynomialCurvedTokenInstance;

  before(async () => {
    ethCurvedToken = await EthPolynomialCurvedToken.new(
      "Convergent",
      "CNVRGNT",
      '18',
      '1',
      '1000',
    );
    
    expect(ethCurvedToken.address).to.exist;

    const poolBalance = await ethCurvedToken.poolBalance();
    expect(poolBalance.toString()).to.equal('0');

    const exponent = await ethCurvedToken.exponent();
    expect(exponent.toString()).to.equal('1');

    const invSlope = await ethCurvedToken.inverseSlope();
    expect(invSlope.eq(new BN(1000))).to.be.true;
  });

  it('Does not allow purchase of zero tokens', async () => {
    try {
      await ethCurvedToken.mint(0, {
        from: user2,
        value: web3.utils.toWei('1', 'ether'),
      });
    } catch (e) {
      const expectedErrorStr = 'VM Exception while processing transaction: revert Must purchase an amount greater than zero.';
      expect(e.toString().indexOf(expectedErrorStr)).to.not.equal(-1)
    }
  });

  it('Does not allow burning of zero tokens', async () => {
    try {
      await ethCurvedToken.burn(0, {
        from: user2,
      });
    } catch (e) {
      const expectedErrorStr = 'VM Exception while processing transaction: revert Must burn an amount greater than zero.';
      expect(e.toString().indexOf(expectedErrorStr)).to.not.equal(-1);
    }
  })

  it('Buying from the curve', async () => {
    const price = await ethCurvedToken.priceToMint(addDecimals(50));
    const price2 = await ethCurvedToken.priceToMint(addDecimals(100));
    const price3 = await ethCurvedToken.priceToMint(addDecimals(150));
    const price4 = await ethCurvedToken.priceToMint(addDecimals(1000));

    // Expect that this is a linear curve, ie. each token bought makes
    // the next token one ether more expensive.
    expect(removeDecimals(price)).to.equal('1.25');
    expect(removeDecimals(price2)).to.equal('5');
    expect(removeDecimals(price3)).to.equal('11.25');
    expect(removeDecimals(price4)).to.equal('500');

    const balBefore = await ethCurvedToken.balanceOf(user1);
    expect(balBefore.toString()).to.equal('0');

    const balBeforeEth = new BN(await web3.eth.getBalance(user1));
    expect(balBeforeEth).to.exist;

    const gasPrice = 23;
    const buyTx: any = await ethCurvedToken.mint(addDecimals(50), {
      from: user1,
      value: web3.utils.toWei('1.25', 'ether'),
      gasPrice,
    });

    const { status, gasUsed } = buyTx.receipt;
    expect(status).to.be.true;

    const gasCost = new BN(gasUsed * gasPrice);

    const balAfter = await ethCurvedToken.balanceOf(user1);
    expect(removeDecimals(balAfter)).to.equal('50');

    const balAfterEth = new BN(await web3.eth.getBalance(user1));
    const balDiffEth = balBeforeEth.sub(balAfterEth).sub(gasCost);
    expect(removeDecimals(balDiffEth)).to.equal('1.25');

    const poolBal = await ethCurvedToken.poolBalance();
    expect(removeDecimals(poolBal)).to.equal('1.25');
  });

  it('Sells back to the curve', async () => {
    const reward = await ethCurvedToken.rewardForBurn(addDecimals(10));
    const reward2 = await ethCurvedToken.rewardForBurn(addDecimals(25));
    const reward3 = await ethCurvedToken.rewardForBurn(addDecimals(50));

    expect(removeDecimals(reward)).to.equal('0.45');
    expect(removeDecimals(reward2)).to.equal('0.9375');
    expect(removeDecimals(reward3)).to.equal('1.25');

    const balBefore = await ethCurvedToken.balanceOf(user1);
    expect(balBefore.toString()).to.equal(addDecimals(50));

    const balBeforeEth = new BN(await web3.eth.getBalance(user1));
    expect(balBeforeEth).to.exist;

    const gasPrice = 23;
    const sellTx: any = await ethCurvedToken.burn(addDecimals(25), {
      from: user1,
      gasPrice,
    });

    const { status, gasUsed } = sellTx.receipt;
    expect(status).to.be.true;

    const gasCost = new BN(gasUsed * gasPrice);

    const balAfter = await ethCurvedToken.balanceOf(user1);
    expect(removeDecimals(balAfter)).to.equal('25');

    const balAfterEth = new BN(await web3.eth.getBalance(user1));
    const balDiffEth = balAfterEth.sub(balBeforeEth).add(gasCost);
    expect(removeDecimals(balDiffEth)).to.equals('0.9375');

    const reward4 = await ethCurvedToken.rewardForBurn(addDecimals(25));
    expect(removeDecimals(reward4)).to.equal('0.3125');

    const sellTx2: any = await ethCurvedToken.burn(addDecimals(25), {
      from: user1,
      gasPrice,
    });

    const { status: status2, gasUsed: gasUsed2 } = sellTx2.receipt;
    expect(status2).to.be.true;

    const gasCost2 = new BN(gasUsed2 * gasPrice);

    const balAfter2 = await ethCurvedToken.balanceOf(user1);
    expect(removeDecimals(balAfter2)).to.equal('0');

    const balAfterEth2 = new BN(await web3.eth.getBalance(user1));
    const balDiffEth2 = balAfterEth2.sub(balAfterEth).add(gasCost2);
    expect(removeDecimals(balDiffEth2)).to.equals('0.3125');
  });
});
