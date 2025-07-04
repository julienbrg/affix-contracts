# Affix Contracts

Affix your digital seal and let the world verify it.

- UI repo: https://github.com/julienbrg/affix-ui
- Live demo: https://affix-ui.vercel.app/

Organisations, businesses and individuals can authenticate their documents using Filecoin while keeping their existing workflows intact. Anyone can then instantly verify that documents are genuine and unaltered.

### Install

```bash
# Clone the repository
git clone https://github.com/julienbrg/affix-contracts.git
cd affix-contracts

# Install dependencies
bun install

# Build the project
forge build
```

## Test

Run the basic test suite:

```bash
forge test
```

## Deploy

In a seperated shell:

```bash
supersim fork --chains=op
```

Then:

```bash
forge script script/DeployAffixFactory.sol --rpc-url op --broadcast
forge script script/RegisterInstitution.s.sol --rpc-url op --broadcast
forge script script/AddAgent.s.sol --rpc-url op --broadcast
forge script script/IssueDocument.s.sol --rpc-url op --broadcast
forge script script/VerifyDocument.s.sol --rpc-url op --broadcast
```

## Deploy to Calibration

Deploying to Filecoin Calibration testnet requires special configuration due to EVM compatibility differences.

### Prerequisites

1. **Get Calibration testnet funds**: Visit the [Calibration Faucet](https://faucet.calibration.fildev.network/) and
   request tFIL for your deployer address.

2. **Set environment variables**:

```bash
export PRIVATE_KEY="your_private_key_here"
export INSTITUTION_NAME="Your Institution Name"
export INSTITUTION_URL="https://your-institution.com"
export ADMIN_ADDRESS="0x_your_admin_address"
```

### Deployment Steps

#### 1. Deploy Factory

```bash
forge script script/DeployAffixFactory.sol \
  --rpc-url https://api.calibration.node.glif.io/rpc/v1 \
  --broadcast \
  --gas-limit 30000000 \
  --gas-price 150000000000 \
  --evm-version paris \
  --skip-simulation
```

#### 2. Update Factory Address

After successful factory deployment, update the factory address in `script/RegisterInstitution.s.sol`:

```solidity
// Update this line with your deployed factory address
address constant AFFIX_FACTORY_ADDRESS = 0x1928Fb336C74432e129142c7E3ee57856486eFfa;
```

#### 3. Register Institution

```bash
forge script script/RegisterInstitution.s.sol \
  --rpc-url https://api.calibration.node.glif.io/rpc/v1 \
  --broadcast \
  --gas-limit 30000000 \
  --gas-price 150000000000 \
  --evm-version paris \
  --skip-simulation
```

#### 4. Add Agents (Optional)

```bash
export AGENT_ADDRESS="0x_agent_address"
export REGISTRY_ADDRESS="0x_registry_address_from_step_3"

forge script script/AddAgent.s.sol \
  --rpc-url https://api.calibration.node.glif.io/rpc/v1 \
  --broadcast \
  --gas-limit 30000000 \
  --gas-price 150000000000 \
  --evm-version paris \
  --skip-simulation
```

#### 5. Issue Documents

```bash
export DOCUMENT_CID="your_ipfs_cid"
export DOCUMENT_METADATA="document description"

forge script script/IssueDocument.s.sol \
  --rpc-url https://api.calibration.node.glif.io/rpc/v1 \
  --broadcast \
  --gas-limit 30000000 \
  --gas-price 150000000000 \
  --evm-version paris \
  --skip-simulation
```

### Calibration-Specific Notes

- **EVM Version**: Use `--evm-version paris` to avoid PUSH0 opcode compatibility issues
- **Gas Limits**: Filecoin requires higher gas limits (30M recommended) for message storage
- **Skip Simulation**: Use `--skip-simulation` to bypass gas estimation issues
- **Explorer**: View contracts on [Calibration FilScan](https://calibration.filscan.io/)

### Troubleshooting

**Gas Estimation Errors**: If you see "GasLimit field cannot be less than the cost of storing a message on chain",
increase the gas limit and add `--skip-simulation`.

**EIP-3855 Warnings**: This warning about PUSH0 opcode is expected on Filecoin. Using `--evm-version paris` resolves
compatibility issues.

**Contract Not Found**: Ensure the factory deployed successfully by checking the transaction hash on
[Calibration FilScan](https://calibration.filscan.io/).

### Send some funds

```bash
➜ cast send 0x201feEbC7803799A8ADd8eF765642C51b7445bc6 \
  --value 0.1ether \
  --rpc-url https://api.calibration.node.glif.io/rpc/v1 \
  --private-key 0x...
```

## Support

Feel free to reach out to [Julien](https://github.com/julienbrg) on [Farcaster](https://warpcast.com/julien-),
[Element](https://matrix.to/#/@julienbrg:matrix.org),
[Status](https://status.app/u/iwSACggKBkp1bGllbgM=#zQ3shmh1sbvE6qrGotuyNQB22XU5jTrZ2HFC8bA56d5kTS2fy),
[Telegram](https://t.me/julienbrg), [Twitter](https://twitter.com/julienbrg),
[Discord](https://discordapp.com/users/julienbrg), or [LinkedIn](https://www.linkedin.com/in/julienberanger/).

## Credits

I want to thank [Paul Razvan Berg](https://github.com/paulrberg) for his work on the
[Foundry template](https://github.com/PaulRBerg/foundry-template) we used.

## License

This project is licensed under the GNU General Public License v3.0.

<img src="https://bafkreid5xwxz4bed67bxb2wjmwsec4uhlcjviwy7pkzwoyu5oesjd3sp64.ipfs.w3s.link" alt="built-with-ethereum-w3hc" width="100"/>
