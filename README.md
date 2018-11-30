[![Build Status](https://travis-ci.org/convergentcx/Arc.svg?branch=master)](https://travis-ci.org/convergentcx/Arc)

# Arc

[Bonding Curves](https://medium.com/@simondlr/tokens-2-0-curved-token-bonding-in-curation-markets-1764a2e0bee5) 
are a method of token issuance which allow for continuous liquidity of the issued token through
the maintenance of a reserve. External users are free to purchase or sell tokens _into_ the curve by
submitting transactions to the bonding curve smart contract. The bonding curve will mint (buy) or 
burn (sell) new tokens depending on the action external users make. The name bonding curve comes from
the fact that the price of the token will move on a determined path that can be visually viewed as a curve.

## Notes on Upgradability

Arc uses [ZeppelinOS](https://github.com/zeppelinos/zos) to enable upgradibility in its contracts. For those
not yet familiar with the proxy pattern, the contracts may look a bit strange at first. If you want to 
make yourself more comfortable with how the upgrade pattern works check out the great post on Zeppelin's 
[blog](https://blog.zeppelinos.org/proxy-patterns/).

That the contracts contained in the Arc library can be upgraded does not mean that they will be,
all users or end consumers will have to `opt-in` to an upgrade. The way to opt in to an upgrade is
by changing the the logic contract for which the the proxy points at. For users of Arena, we are working
on nice and intuitive UI components to allow for this. For developers who use Arc, it will require some
knowledge on how to perform the action themselves. 

## Testing

Clone this repository and install dependencies:

```
$ git clone git@github.com:convergentcx/Arc.git
$ yarn
```

Then compile the smart contracts and generate the TypeScript bindings:

```
$ yarn generate
```

Now in one window start the development chain:

```
$ yarn ganache
```

In other window run the tests:

```
$ yarn test
```

## Running the Demo

Start by installing dependencies and running ganache in one console:

```
$ yarn
$ yarn ganache
```

In other console run:

```
$ yarn compile:dapp
```

Remaining in the new console, move to the `dapp/` directory and run the following:

```
$ yarn
$ yarn start
```

Navigate to `http://localhost:3000` in a web browser.
