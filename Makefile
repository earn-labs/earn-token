
-include .env

.PHONY: all test clean deploy

DEFAULT_ANVIL_ADDRESS := 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install:; forge install foundry-rs/forge-std --no-commit && forge install Cyfrin/foundry-devops --no-commit && forge install OpenZeppelin/openzeppelin-contracts --no-commit

# update dependencies
update:; forge update

# compile
build:; forge build

# test
test :; forge test 

# test coverage
coverage:; @forge coverage --contracts src
coverage-report:; @forge coverage --contracts src --report debug > coverage.txt

# take snapshot
snapshot :; forge snapshot

# format
format :; forge fmt

# spin up local test network
anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

# spin up fork
fork :; @anvil --fork-url ${RPC_MAIN} --fork-block-number <blocknumber> --fork-chain-id <fork id> --chain-id <custom id>

# security
slither :; slither ./src 

# deployment
deploy-local: 
	@forge script script/DeployReflectionToken.s.sol:DeployReflectionToken --rpc-url $(RPC_LOCALHOST) --private-key ${DEFAULT_ANVIL_KEY} --sender ${DEFAULT_ANVIL_ADDRESS} --broadcast 

deploy-testnet: 
	@forge script script/DeployReflectionToken.s.sol:DeployReflectionToken --rpc-url $(RPC_TEST) --account ${ACCOUNT_NAME} --sender ${ACCOUNT_ADDRESS} --broadcast --verify --etherscan-api-key ${ETHERSCAN_KEY} -vvvv

deploy-mainnet: 
	@forge script script/DeployReflectionToken.s.sol:DeployReflectionToken --rpc-url $(RPC_MAIN) --account ${ACCOUNT_NAME} --sender ${ACCOUNT_ADDRESS} --broadcast --verify --verifier-url "https://api.routescan.io/v2/network/mainnet/evm/43114/etherscan" --etherscan-api-key ${ETHERSCAN_KEY} -vvvv

verify:
	@forge verify-contract 0xd86b56076b5ed2f31B8C34047E275d1C756a3783 src/ReflectionToken.sol:ReflectionToken --verifier-url "https://api.routescan.io/v2/network/mainnet/evm/43114/etherscan" --etherscan-api-key ${ETHERSCAN_KEY} --num-of-optimizations 200 --compiler-version v0.8.20+commit.a1b79de6 --constructor-args 00000000000003b9aca00000000000000000000000000000000000000000000000000000000000000271000000000000000000000000040a040781e7c28fc7aea8e00040e4a0242551a520000000000000000000000000000000000000000000000000000000000000006546573742031000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055445535431000000000000000000000000000000000000000000000000000000

# cast abi-encode "constructor(string,string,uint256,uint256,address)" "Test 1" "TEST1" 1000000000 10000 0x40A040781E7C28Fc7AEa8E00040e4a0242551A52
# = 0x00000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e0000000000000000000000000000000000000000000000000000000003b9aca00000000000000000000000000000000000000000000000000000000000000271000000000000000000000000040a040781e7c28fc7aea8e00040e4a0242551a520000000000000000000000000000000000000000000000000000000000000006546573742031000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055445535431000000000000000000000000000000000000000000000000000000

# command line interaction
contract-call:
	@cast call <contract address> "FunctionSignature(params)(returns)" arguments --rpc-url ${<RPC>}

-include ${FCT_PLUGIN_PATH}/makefile-external