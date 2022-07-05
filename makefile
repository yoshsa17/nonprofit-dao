-include .env

tests:; forge clean && forge test --optimize --optimizer-runs 1000000 -vvvv

build:; forge clean && forge build --optimize --optimizer-runs 1000000

clean:; forge clean

deploy:; forge deploy