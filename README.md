# Cross-chain Gov

Verify document authenticity.

### Install

```bash
# Clone the repository
git clone https://github.com/julienbrg/veridocs-contracts.git
cd veridocs-contracts

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
forge script script/DeployVeridocsFactory.sol --rpc-url op --broadcast
forge script script/RegisterInstitution.s.sol --rpc-url op --broadcast
forge script script/AddAgent.s.sol --rpc-url op --broadcast
forge script script/IssueDocument.s.sol --rpc-url op --broadcast
forge script script/VerifyDocument.s.sol --rpc-url op --broadcast
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
