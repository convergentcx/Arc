import { expect } from 'chai';
import { SpreadEtherInstance } from '../../types/truffle-contracts';

import BN = require('bn.js');
import Web3 = require('web3');

import { findEvent } from '../helpers';

declare const web3: Web3;

const SpreadEther = artifacts.require('SpreadEther');

contract('SpreadEther', ([owner, user1, user2]) => {
  let spreadEther: SpreadEtherInstance;

  before(async () => {

  });

  it('Sanity checks', async () => {

  });
});
