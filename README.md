# REFLECTION TOKEN (UPDATED!)

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg?style=for-the-badge)
![Forge](https://img.shields.io/badge/forge-v1.0.0-blue.svg?style=for-the-badge)
![Solc](https://img.shields.io/badge/solc-v0.8.20-blue.svg?style=for-the-badge)
[![GitHub License](https://img.shields.io/github/license/trashpirate/foundry-starter?style=for-the-badge)](https://github.com/trashpirate/reflection-token/blob/master/LICENSE)

[![Website: trashpirate.io](https://img.shields.io/badge/Portfolio-00e0a7?style=for-the-badge&logo=Website)](https://trashpirate.io)
[![LinkedIn: nadinaoates](https://img.shields.io/badge/LinkedIn-0a66c2?style=for-the-badge&logo=LinkedIn&logoColor=f5f5f5)](https://linkedin.com/in/nadinaoates)
[![Twitter: 0xTrashPirate](https://img.shields.io/badge/@0xTrashPirate-black?style=for-the-badge&logo=X)](https://twitter.com/0xTrashPirate)


## About

_**DISCLAIMER: This code is provided as-is and has not been audited for security or functionality. Use at your own risk.**_

This repo contains the smart contract code and a full test suite for a Reflection Token based on the ERC20 standard. The contract is designed to automatically distribute transaction fees to token holders, providing them with automatic revenue share from the transaction volume. The code is adapted from the [RFI](https://etherscan.io/address/0xa1afffe3f4d611d252010e3eaf6f4d77088b0cd7#code) smart contract, with modifications to remove liqudity and marketing fees and leveraging Openzepplin contracts and a newer Solidity version for security and best practices. A detailed description of the reflection mechanism can be found [here](https://github.com/regohiro/reflect-contract-doc/blob/main/). The PdF version is available in the [docs](https://github.com/trashpirate/reflection-token/tree/master/docs). 

The repo also includes a short error analysis as a discrepancy between total supply and the total sum of balances was discovered during testing (see `test/invariant/ReflectionTokenInvariantTest::invariant__TokenSupply`). The issue likely arises from rounding errors during oprations that convert from R to T space and vice versa. It was found that the rounding error increases with the number of accounts receiving reflections but decreases with the number of transactions. While the data for this analysis is insufficient to draw any definite conclusions, it looks like that the error is subject to increased volatilty and randomness the higher the number of transfers. Based on the available data, the rounding error seems to remain in the lower digits and is unlikely to have a significant impact on the overall functionality of the contract.

## Installation

### Install dependencies
```bash
$ make install
```

## Usage
Before running any commands, create a .env file and add the following environment variables:

```bash
# network configs
RPC_LOCALHOST="http://127.0.0.1:8545"

# ethereum nework
RPC_TEST=<rpc url>
RPC_MAIN=<rpc url>
ETHERSCAN_KEY=<api key>

# accounts to deploy/interact with contracts
ACCOUNT_NAME="account name"
ACCOUNT_ADDRESS="account address"
```

Update chain ids in the `HelperConfig.s.sol` file for the chain you want to configure:

- Ethereum: 1 | Sepolia: 11155111 
- Base: 8453 | Base sepolia: 84532
- Bsc: 56 | Bsc Testnet: 97
- Avalanche: 43114 | Fuji: 43113

### Run tests
```bash
$ forge test
```

### Deploy contract on testnet
```bash
$ make deploy-testnet
```

### Deploy contract on mainnet
```bash
$ make deploy-mainnet
```

## Deployments

### Testnet
https://sepolia.etherscan.io/address/0xc8bdd7805fad8dc59b753fecccdf17b98c17465b

### Mainnet
Deployment of similar version on 10/08/2023:   
Contract: https://etherscan.io/token/0x0b61c4f33bcdef83359ab97673cb5961c6435f4e  
Chart: https://www.dextools.io/app/en/ether/pair-explorer/0x32558f1214bd874c6cbc1ab545b28a18990ff7ee  


## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Author

👤 **Nadina Oates**

* Website: [trashpirate.io](https://trashpirate.io)
* Twitter: [@0xTrashPirate](https://twitter.com/0xTrashPirate)
* Focus: [@trashpriate](https://focus.xyz/trashpirate)
* Github: [@trashpirate](https://github.com/trashpirate)
* LinkedIn: [@nadinaoates](https://linkedin.com/in/nadinaoates)


## 📝 License

Copyright © 2025 [Nadina Oates](https://github.com/trashpirate).

