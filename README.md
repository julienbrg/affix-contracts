# Affix Contracts

Affix your onchain seal and let the world verify it.

- UI repo: https://github.com/julienbrg/affix-ui
- Live demo: https://affix-ui.vercel.app

Organisations, businesses and individuals can authenticate their documents using Filecoin while keeping their existing
workflows intact. Anyone can then instantly verify that documents are genuine and unaltered.

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
forge script script/RegisterEntity.s.sol --rpc-url op --broadcast
forge script script/AddAgent.s.sol --rpc-url op --broadcast
forge script script/IssueDocument.s.sol --rpc-url op --broadcast
forge script script/VerifyDocument.s.sol --rpc-url op --broadcast
```

## Deploy to OP Mainnet

#### 1. Deploy Factory

```bash
forge script script/DeployAffixFactory.sol \
  --rpc-url optimism \
  --broadcast \
  --verify
```

#### 2. Update Factory Address

After successful factory deployment, update the factory address in `script/RegisterEntity.s.sol`:

```solidity
// Update this line with your deployed factory address
address constant AFFIX_FACTORY_ADDRESS = <NEW_FACTORY_ADDRESS>;
```

#### 3. Register Entity

```bash
forge script script/RegisterEntity.s.sol \
  --rpc-url optimism \
  --broadcast \
  --verify
```

#### 4. Add Agents (Optional)

```bash
forge script script/AddAgent.s.sol \
  --rpc-url optimism \
  --broadcast
```

#### 5. Issue Documents

```bash
forge script script/IssueDocument.s.sol \
  --rpc-url optimism \
  --broadcast
```

## Support

Feel free to reach out to [Julien](https://github.com/julienbrg) on [Farcaster](https://warpcast.com/julien-),
[Element](https://matrix.to/#/@julienbrg:matrix.org),
[Status](https://status.app/u/iwSACggKBkp1bGllbgM=#zQ3shmh1sbvE6qrGotuyNQB22XU5jTrZ2HFC8bA56d5kTS2fy),
[Telegram](https://t.me/julienbrg), [Twitter](https://twitter.com/julienbrg),
[Discord](https://discordapp.com/users/julienbrg), or [LinkedIn](https://www.linkedin.com/in/julienberanger/).

## License

This project is licensed under the GNU General Public License v3.0.

<img src="https://bafkreid5xwxz4bed67bxb2wjmwsec4uhlcjviwy7pkzwoyu5oesjd3sp64.ipfs.w3s.link" alt="built-with-ethereum-w3hc" width="100"/>
