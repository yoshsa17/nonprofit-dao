# ref: https://github.com/smartcontractkit/foundry-starter-kit/blob/main/Makefile
-include .env

# setup the environment
all: clean remove install update build setup-npm

clean :; forge clean

remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install foundry-rs/forge-std && forge install OpenZeppelin/openzeppelin-contracts

update :; forge update

build :;  forge build --optimize --optimizer-runs 1000000

setup-npm :; npm install

# test
tests :; forge clean && forge test --optimize --optimizer-runs 1000000 -vvvv

# deployment 
local-node :; anvil --block-time 13 --host 0.0.0.0 --mnemonic 'test test test test test test test test test test test rabbit'

deploy :; forge script script/deploy.s.sol:DeployContracts --fork-url http://localhost:8545  \
    --private-key 0xb2fcc1d62f49bbb286835fe809c5644860229ed5beef6ee9fea090bf88601b57 --broadcast -vvvv
