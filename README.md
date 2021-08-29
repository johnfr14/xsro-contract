# xSRO Smart Contracts

## Contracts

- xSRO
- NFT
- Marketplace
- Swap

## Scripts

- Deploy

## Test

- xSRO
- NFT
- Marketplace
- Swap

## .env

```
INFURA_PROJECT_ID="YOUR_INFURA_API_KEY"
DEPLOYER_PRIVATE_KEY="YOUR_PRIVATE_KEY"
# Api key from the scan network you need to verify on
VERIFY_API_KEY="YOUR_SCAN_API_KEY"
# Options to enable (1) /disable (0)
CONTRACT_SIZER=1
REPORT_GAS=1
OPTIMIZER=1
DOCGEN=0
```

# CMD

- deployment

1. `npx hardhat run scripts/deploy-xSRO.js --network NETWORK_NAME`
1. `npx hardhat run scripts/deploy-Swap.js --network NETWORK_NAME`

- verify

1. `npx hardhat verify --contract contracts/xSRO.sol:SarahRO --network NETWORK_NAME DEPLOYED_CONTRACT_ADDRESS`
1. `npx hardhat verify --contract contracts/Swap.sol:SwapSRO --network NETWORK_NAME DEPLOYED_CONTRACT_ADDRESS "xSRO deployed address" "deployer address"`
