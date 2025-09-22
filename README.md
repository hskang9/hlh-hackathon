# Haifu - Automated Market Making Platform

Haifu is an innovative automated(for real) market making (AMM) platform that combines smart contract-based liquidity pools with algorithmic trading strategies. This repository contains the complete codebase for the Haifu ecosystem, integrating on-chain liquidity management with off-chain trading automation.

🎯 **Pitch Deck**: [View our presentation](https://docs.google.com/presentation/d/1W_37VL8HZLk_k87wigcpRx5mipIHbyn4KX9c-0fXdjc/edit)

## 📁 Project Structure

### 🔐 `haifu-contracts/`
**Smart Contract Infrastructure**

This directory contains the Solidity smart contracts that power Haifu's on-chain functionality, built using Foundry framework.

**Key Components:**
- **`WaifuPool.sol`**: Core liquidity pool contract that enables:
  - Dual-token liquidity provision (base/quote pairs)
  - LP token minting and burning with proportional rewards
  - ETH/WETH support for seamless native token trading
  - Role-based access control for market makers
  - Integration with Standard3.0 matching engine for order execution
  - Automated market making functions (create, update, cancel orders)

**Features:**
- ERC20-compliant LP tokens representing pool shares
- Minimum liquidity protection against rounding attacks  
- Reentrancy protection for secure deposits/withdrawals
- Admin functions for pool management and reserve synchronization

**Setup:**
```bash
cd haifu-contracts
forge build
forge test
```

### 🤖 `hummingbot-standard/`
**Algorithmic Trading Integration**

A specialized fork of Hummingbot that connects automated trading strategies to Central Limit Order Book (CLOB) systems, specifically optimized for integration with Standard3.0 protocol.

**Key Features:**
- **140+ Exchange Connectors**: Support for both centralized (CEX) and decentralized (DEX) exchanges
- **CLOB Integration**: Direct connection to order book-based trading systems
- **Strategy Framework**: Pre-built and customizable trading strategies including:
  - Market making strategies
  - Arbitrage detection and execution
  - Cross-exchange market making (XEMM)
  - Directional trading with technical indicators

**Supported Market Types:**
- **CLOB Spot**: Central limit order book spot markets
- **CLOB Perp**: Perpetual futures markets  
- **AMM**: Automated market maker DEX integration

**Usage:**
```bash
cd hummingbot-standard
# Follow installation guide in README.md
python bin/hummingbot.py
```

### 📊 `match_trade_example.py`
**HyperEVM CLOB Trading Library Example**

A comprehensive Python demonstration showcasing how to interact with HyperEVM's Central Limit Order Book using the StandardWeb3 library.

**Functionality:**
- **Market Operations**: Execute market buy/sell orders with slippage protection
- **Order Management**: Create, update, and cancel limit orders
- **Multi-token Support**: Trade various ERC20 tokens with automatic routing
- **ETH Integration**: Direct ETH trading without WETH wrapping requirements
- **Batch Trading**: Execute multiple trades in sequence for testing/automation

**Key Features:**
```python
# Market buy with slippage protection
await client.market_buy(
    base=base_token,
    quote=quote_token, 
    quote_amount=100,
    slippageLimit=0.1
)

# Market sell with automatic routing
await client.market_sell(
    quote=quote_token,
    base_amount=1,
    slippage_limit=0.1
)
```

**Configuration:**
- Supports multiple networks (Hyperliquid Testnet, Mode Network, etc.)
- Environment variable configuration for private keys and RPC endpoints
- Configurable matching engine addresses for different deployments

## 🏗️ Architecture Overview

Haifu creates a comprehensive ecosystem where:

1. **Smart Contracts** (`haifu-contracts`) manage on-chain liquidity and provide market making infrastructure
2. **Trading Bots** (`hummingbot-standard`) execute sophisticated trading strategies across multiple venues
3. **Integration Layer** (`match_trade_example.py`) demonstrates seamless interaction with CLOB systems

## 🚀 Getting Started

1. **Deploy Smart Contracts**:
   ```bash
   cd haifu-contracts
   forge script script/Counter.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY>
   ```

2. **Set up Trading Bot**:
   ```bash
   cd hummingbot-standard
   ./install
   ./start
   ```

3. **Test CLOB Integration**:
   ```bash
   python match_trade_example.py
   ```

## 🔧 Configuration

Create a `.env` file in the root directory:
```env
PRIVATE_KEY=your_private_key_here
RPC_URL=https://rpc.testnet.mode.network
NETWORK=Hyperliquid Testnet
```

## 📈 Use Cases

- **Liquidity Providers**: Earn fees by providing liquidity to Haifu pools
- **Market Makers**: Use automated strategies to provide continuous liquidity
- **Traders**: Access deep liquidity and tight spreads across multiple venues
- **Arbitrageurs**: Exploit price differences between exchanges automatically

## 🛠️ Technology Stack

- **Smart Contracts**: Solidity, Foundry, OpenZeppelin
- **Trading Engine**: Python, AsyncIO, WebSocket connections
- **Blockchain Integration**: Web3.py, StandardWeb3 library
- **Supported Networks**: Ethereum, Mode Network, Hyperliquid, and more

---

*Built for the HLH Hackathon - Revolutionizing automated market making through smart contract innovation and algorithmic trading.*