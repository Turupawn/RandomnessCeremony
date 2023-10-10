![test workflow](https://github.com/Turupawn/RandomnessCeremony/actions/workflows/test.yml/badge.svg)

# Deployment and verification

## 🚀 How to deploy

```
forge create --rpc-url RPCURL --private-key PRIVATEKEYHERE src/RandomnessCeremony.sol:RandomnessCeremony

forge create --rpc-url RPCURL --private-key PRIVATEKEYHERE  src/LottoAndNFTCeremony.sol:LottoAndNFTCeremony --constructor-args "0xRANDOMNESSCEREMONYADDRESS"
```

## ✅ How to verify on Optimistic Etherscan

```
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_API_KEY forge verify-contract YOUR_RANDOMNESS_CEREMONY_ADDRESS src/RandomnessCeremony.sol:RandomnessCeremony --chain-id 10 --verifier-url https://api-optimistic.etherscan.io/api --verifier etherscan

ETHERSCAN_API_KEY=YOUR_ETHERSCAN_API_KEY forge verify-contract YOUR_LOTTO_AND_NFT_CEREMONY src/LottoAndNFTCeremony.sol:LottoAndNFTCeremony --chain-id 10 --verifier-url https://api-optimistic.etherscan.io/api --verifier etherscan --constructor-args $(cast abi-encode "constructor(address)" "YOUR_RANDOMNESS_CEREMONY_ADDRESS")
```

# Optimism Mainnet Deploy

## Legacy (v0.1)

```
Randomness Ceremony
0x986E945007c64aF4660581d64503795B90fA7Da6
LottoAndNFTCeremony
0xa5e742b4aCCD558F2D17555E4387099f6D4261cC
```

## Live (v0.2)

```
Randomness Ceremony
0x440897cb529c6DEc3C0a53d630e72f667624694d
LottoAndNFTCeremony
0x10445fff1600AD3e38276EE3ec7CF7625D852687
```

# ? Deploy

## Live (v0.2)

```
Randomness Ceremony
0xD9BcFd43E6BA76b1468D0a66325C0c06D6DACf33
LottoAndNFTCeremony
0x24EF68753793b732972E83B67B70409D4049A487
```