# IntelliCasino Betting Smart Contract

## Overview

The **IntelliCasino Betting Smart Contract** provides a decentralized platform for spectators to place bets on a quiz player's performance in real-time games. The contract is built on the Ethereum blockchain and manages two types of bets: bets on the quiz player winning (by achieving 75%+ accuracy) and bets on IntelliCasino winning (if the player scores below 75%). It leverages Solidity, follows security best practices, and ensures proper fund distribution between the winning side and the casino's commission.

## Features

- **Decentralized Betting**: Allows spectators to place bets on a quiz game outcome (player vs. IntelliCasino).
- **Transparent Fund Management**: Tracks bets on both sides (player and casino) and securely stores funds during gameplay.
- **Secure Fund Distribution**: Distributes winnings fairly to bet winners based on a dynamic payout ratio.
- **Commission Collection**: Automatically deducts a 3% commission from the total bet pool before distributing winnings.
- **Security Best Practices**: Reentrancy attack protection and secure transfer mechanisms ensure the contract’s robustness.

## Functionality

### 1. **Game Creation**
   - A new game can be created by the casino owner (which is the frontend application).
   - Each game has an ID provided by the frontend and can only accept bets during its **OPEN** state.

### 2. **Bet Placement**
   - Spectators can place bets on the player or casino using the `placeBet()` function.
   - The contract ensures that spectators can only place bets when the game is in an **OPEN** state.
   - Spectators can add to their existing bets until the game is closed.

### 3. **Bet Withdrawal**
   - Before the game is closed, spectators can withdraw their placed bets using `withdrawBet()`.
   - The contract handles bet removal from the active pool and ensures the user's funds are transferred back securely.

### 4. **Game Closure**
   - Once the game begins, the owner can close the game using the `closeGame()` function, preventing further bets or withdrawals.

### 5. **Winnings Distribution**
   - After the game concludes, the contract calculates the payout ratio and distributes the winnings to the winners (based on whether the player won or the casino won).
   - The casino takes a 3% commission from the total bet pool before winnings are distributed.
   - The contract ensures enough funds are available before any transfer.

### 6. **Security Features**
   - **Reentrancy Guards**: Each bet and withdrawal updates the contract’s state before any transfer, preventing reentrancy attacks.
   - **Modifiers for Ownership**: Only the contract owner can create games, close games, or distribute winnings, ensuring that the contract is operated by authorized entities.
   - **Gas Optimization**: Careful use of `memory` and `storage` for minimizing unnecessary gas consumption.

## Foundry

**Foundry is a blazing fast, portable, and modular toolkit for Ethereum application development written in Rust.** It is used for building, testing, and deploying this contract.

### Foundry Components:

- **Forge**: Ethereum testing framework.
- **Cast**: Swiss army knife for interacting with EVM smart contracts.
- **Anvil**: Local Ethereum node for testing.
- **Chisel**: Solidity REPL for quick prototyping.

### Usage with IntelliCasino

#### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/IntelliCasinoBetting.s.sol:IntelliCasinoBettingDeploymentScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

## Future Features
- Metamask Integration: Spectators will authenticate with Metamask wallets to place bets using their ETH.
- GraphQL and WebSocket Integration: Real-time data streaming of games will allow spectators to track the game’s progress and place bets in live environments.
- Role-based Authentication: Future iterations will include role-based access control for players, spectators, and casino operators.

