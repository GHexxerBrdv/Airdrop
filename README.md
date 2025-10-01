# Airdrop Smart contract

- [About project](#about-project)
- [Getting Started](#getting-started)
  - [Requirements](#requirements)
  - [Quickstart](#quickstart)
- [Usage](#usage)
  - [Pre-deploy: Generate merkle proofs](#pre-deploy-generate-merkle-proofs)
- [Deploy](#deploy)
  - [Interacting with contracts](#interacting-with-contracts)
    - [Deploy token and airdrop contract ](#deploy-token-and-airdrop-contract)
    - [Interact with deployed contract](#interact-with-deployed-contract)
  - [Testing](#testing)
    - [Test Coverage](#test-coverage)
  - [Estimate gas](#estimate-gas)
- [Formatting](#formatting)
- [Thank you!](#thank-you)

# About project

There is three version of the airdrop smart contract.

- V1: Admin will set an array of users and their corresponding claimable amount. Which is not secure and more gas consuming.
- V2: This version of airdrop is very gas efficient and secure, by setting the merkle root of the users and their claimable amount calculated off-chain. This version of airdrop allows user to submit proof and claim their amount by permit other or directly from the contract.
- V3: This version of airdrop will be held in two phase.
  1) private phase :- only whitelisted address can claim the amount of tokens by permit other user or directly from the contract.
  2) public phase :- anyone can claim upto one airdrop token from the airdrop contract.

**Note:** The private phase will be set for predefined time duration. After that it will automatically set to the public phase, if there is a user who has not claimed their airdrop from private phase, thier token will be automatically transfered to the public phase.

Chainlink automation has been set for the automatically shift between both phase.

# Getting Started

## Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- [foundry](https://getfoundry.sh/)
 

## Quickstart

```bash
git clone https://github.com/GHexxerBrdv/Airdrop.git
cd Airdrop
forge install # or forge build
```

# Usage

## Pre-deploy: Generate merkle proofs

We are going to generate merkle proofs for an array of addresses to airdrop funds to.

If you'd like to work with a different array of addresses , you have to change the addresses in the `whitelist` list in `GenerateInput.s.sol` with your metamask accounts addresses.

To generate the input file and then the merkle root and proofs, run the following:

using the commands directly:

```bash
forge script script/merkletree/GenerateInput.s.sol:GenerateInput 
forge script script/merkletree/MakeMerkle.s.sol:MakeMerkle
```

Then, retrieve the `root` (there may be more than 1, but they will all be the same) from `script/merkletree/target/output.json`.

# Deploy 

(Note :- All the commands and instructions are for version 3 if you want to deploy other versions then the process will be same)

## Interacting with contracts

we are going to deploy contracts on polygon, you can deploy and interact on anychain. 

make sure you have test faucet to deploy and interact.

make an .env file and store there your metamask account address and private key. Also you have to add rpc url of the polygon amoy test chain. If you are working on other chain then add their rpc url. get rpc from the alchamy or infura.

The .env file will look like this

```js
ACC1= metamask account address
PRIV1= metamask account private key
ACC2=
PRIV2=
ACC3=
PRIV3=
ACC4=
PRIV4=
ACC5=
PRIV5=
ACC6=
PRIV6=
RSK= rootstock rpc url [get rpc](https://dashboard.alchemy.com/)
KEY= etherscan api key in case if you want to verify the contract
```

I have taken multiple accounts and their corresponding private keys to perform claims.

You have to run following command to access accounts and privatkeys from .env file

```bash
source .env
```

### Deploy token and airdrop contract 

```bash
forge script script/Proton.s.sol --private-key $PRIV1 --rpc-url $POLY --broadcast
```

```bash
forge script script/AirdropV3.s.sol --private-key $PRIV1 --rpc-url $POLY --broadcast
```

### Interact with deployed contract

Run these commands to interact with deployed airdrop contract.

this command will configure the airdrop seasone.
```bash
forge script script/InteractionsV3.s.sol:InteractionV3 --private-key $PRIV1 --rpc-url $POLY --broadcast
```

this command will allow user to claim airdrop with valid proof.
```bash
forge script script/InteractionsV3.s.sol:AirdropClaim --private-key $PRIV1 --rpc-url $POLY --broadcast
```

this command will view the state change in airdrop after claiming the airdrop.
```bash
forge script script/InteractionsV3.s.sol:ViewState --private-key $PRIV1 --rpc-url $POLY --broadcast
```

## Transactions on block explorer

After deploying the contract on rootstock testnet you can see the transaction on [explorer](https://explorer.testnet.rootski.io/)

You have to just enter your deployed contract address or the transaction hash in serach bar in the explorer. And you can the trasaction over there.


## Testing

```bash
foundryup
forge test
```

### Test Coverage

```bash
forge coverage
```

## Estimate gas

You can estimate how much gas things cost by running:

```bash
forge snapshot
```

# Formatting

To run code formatting:
```bash
forge fmt
```

# Thank you!