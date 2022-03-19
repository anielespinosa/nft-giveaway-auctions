# NFT Daily Giveaway Auctions

**Steps to follow:**  
1. nft contract:           setApprovalForAll(**CONTRACT_DAILYGIVEAWAY**)<br />
2. nft contract:           sendNFTto(**CONTRACT_DAILYGIVEAWAY**)<br />
3. dailygiveawaycontract:  startAuction()<br />
4. dailygiveawaycontract:  ...placing bids...<br />
5. dailygiveawaycontract:  endAuction()<br />
6. dailygiveawaycontract:  requestRandomWords()<br />
7. dailygiveawaycontract:  randomDailyWinner()<br />
8. dailygiveawaycontract:  sendRewardsDailyWinner()<br />
**repeat from 2.**<br />

**Note: addresses used in these files are test wallets with testnet ETH**
