import { expect } from 'chai';
import { EthPolynomialCurvedTokenInstance, SignInstance } from '../types/truffle-contracts';

import BN = require('bn.js');
import Web3 = require('web3');

declare const web3: Web3;

const EthPolynomialCurvedToken = artifacts.require('EthPolynomialCurvedToken');
const Sign = artifacts.require('Sign');

const addDecimals = (numTokens: any) => {
  return web3.utils.toWei(String(numTokens), 'ether').toString();
}

const removeDecimals = (tokens: any) => {
  return web3.utils.fromWei(tokens, 'ether').toString();
}

contract('Sign', ([owner, user1, user2]) => {
  let ethCurvedToken: EthPolynomialCurvedTokenInstance;
  let sign: SignInstance;

  before(async () => {
    ethCurvedToken = await EthPolynomialCurvedToken.new(
      "Convergent",
      "CNVRGNT",
      18,
      1,
      1000
    )
    
    expect(ethCurvedToken.address).to.exist;

    const poolBalance = await ethCurvedToken.poolBalance();
    expect(poolBalance.eq(new BN(0))).to.be.true;

    const exponent = await ethCurvedToken.exponent();
    expect(exponent.eq(new BN(1))).to.be.true;

    const slope = await ethCurvedToken.slope();
    expect(slope.eq(new BN(1000))).to.be.true;

    sign = await Sign.new(ethCurvedToken.address);
    expect(sign.address).to.exist;

    const signOwner = await sign.owner();
    expect(signOwner).to.equal(owner);

    const curSign = await sign.sign();
    expect(curSign).to.equal("0x" + "00".repeat(32));

    const token = await sign.token();
    expect(token).to.equal(ethCurvedToken.address);
  });


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
    assert.isTrue(balBefore.eq(new BN(0)));

    const buyTx: any = await ethCurvedToken.mint(50, {
      from: user1,
      value: web3.utils.toWei('1.25', 'ether')
    });

    expect(buyTx.receipt.status).to.be.true;

    const balAfter = await ethCurvedToken.balanceOf(user1);
    expect(balAfter.toString()).to.equal('50');

    // const poolBal = await ethCurvedToken.poolBalance();
    // expect(poolBal.toString()).to.equal(web3.utils.toWei('1.25', 'ether').toString());
  });

  it('Sells back to the curve', async () => {
    // const reward = await ethCurvedToken.rewardForBurn(1);
    // const reward2 = await ethCurvedToken.rewardForBurn(2);
    // const reward3 = await ethCurvedToken.rewardForBurn(3);

    // console.log(reward, reward2, reward3);
    // assert.isTrue(reward.eq(new BN(3)));
    // assert.isTrue(reward2.eq(new BN(5)));
    // assert.isTrue(reward3.eq(new BN(1)));


  })
})