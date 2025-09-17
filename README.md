

# ENS (Ethereum Name Service) Project

This project implements a simplified Ethereum Name Service (ENS) using Solidity smart contracts and the Foundry development toolkit.

## Project Overview

The ENS contract allows users to register human-readable names, associate them with Ethereum addresses, and link an IPFS image hash for profile or avatar purposes. Names can be updated and transferred securely.

## Main Features

- **Name Registration:** Users can register unique names and associate them with their address and an IPFS image hash.
- **Name Resolution:** Retrieve the address and image hash associated with a registered name.
- **Name Update:** Owners can update the resolved address and image hash for their names.
- **Ownership Transfer:** Names can be securely transferred to another address.
- **Security:** Custom errors and access control to ensure only owners can manage their names.

## Smart Contracts

- `Ens.sol`: Main contract for registering, updating, resolving, and transferring ENS names.

## Getting Started

This project uses [Foundry](https://book.getfoundry.sh/) for development, testing, and deployment.

## Usage

### Build

```shell
forge build
```

### Test

```shell
forge test
```

### Format

```shell
forge fmt
```

### Gas Snapshots

```shell
forge snapshot
```

### Anvil (Local Node)

```shell
anvil
```

### Deploy Example

```shell
forge script script/DeployEns.s.sol --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast (Interact with Contracts)

```shell
cast <subcommand>
```

### Help

```shell
forge --help
anvil --help
cast --help
```
