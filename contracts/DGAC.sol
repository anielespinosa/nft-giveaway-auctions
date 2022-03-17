//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./MonthlyGiveawayAuction.sol";
import "./FuckTheWhat.sol";
import "./VRFv2Consumer.sol";

// for NFT stuffs
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// for KeeperChainlink
//import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

/**
 * @title DailyGiveaway
 * @dev Ether Giveaway that transfer contract amount to winner
 */
//contract DailyGiveawayAuction is VRFv2Consumer, KeeperCompatibleInterface {
contract DailyGiveawayAuction is VRFv2Consumer {
    using Strings for uint256;

    // Events
    event Start(bool _started, bool _ended, uint256 _nftId);
    event PlaceBid(address indexed sender, uint256 indexed amount);
    event NextMinimumBid(uint256 _nextminbid);
    event End(
        address indexed highestBidder,
        uint256 indexed highestBid,
        bool _started,
        bool _ended
    );
    event AuctionForceEnd(bool _started, bool _ended);
    event NftforceSent(bool _nftforcesent);
    event RandomWinnerSelected(address indexed dailyWinner);
    event DailyReward(uint256 indexed dailyReward);
    event DailyRemainToMGA(uint256 indexed dailyRemainsToMGA);
    event DailyBidderReset(bool dailybidderreset);

    bool public started;
    bool public ended;
    uint256 public endAt;

    // list of players registered in lottery
    address payable[] public dailyPlayers;
    address payable public dailyWinner;

    uint256 public percentageDailyWinner = 25;
    uint256 public percentageDeveloppers = 10;

    uint256 public startingPrice = 0.00002 ether;
    uint256 public additionalMinimumBid = 0.00001 ether;
    uint256 public highestBid;
    address payable public highestBidder;
    uint256 public dailyReward;

    // info for interaction with MonthlyGiveawayAuction Contract
    MonthlyGiveawayAuction mga;
    address payable public addressMGA;
    address payable public addressDGA;
    address payable public admin;
    address payable private adminPersonalAddress;

    // for NFT stuffs
    IERC721 public nft;
    uint256 public nftId;

    /* FOR RANDOMNESS IN CHAINLINK VRF*/
    VRFv2Consumer vrf;

    // FOR KEEPERCHAINLINK
    /*uint256 public immutable interval;
    uint256 public startLastTimeStamp;
    uint256 public endLastTimeStamp;*/

    constructor(
        address _addressMGA,
        IERC721 _nft,
        address _adminPersAddr,
        // uint _updateInterval
        uint64 _subscriptionId
    ) VRFv2Consumer(_subscriptionId) {
        admin = payable(msg.sender);
        addressMGA = payable(_addressMGA);
        addressDGA = payable(address(this));
        mga = MonthlyGiveawayAuction(payable(_addressMGA));
        adminPersonalAddress = payable(_adminPersAddr);
        //interval = updateInterval;
        //lastTimeStamp = block.timestamp;
        nft = _nft;
        nftId = 0;
        started = false;
        ended = true;
    }

    receive() external payable {}

    function startAuction() external {
        require(started == false, "Auction already started!");
        require(ended == true, "Auction is ended!");
        require(msg.sender == admin, "You cannot start the Auction!");

        started = true;
        ended = false;

        nftId = nftId + 1;

        highestBidder = payable(address(0));
        highestBid = additionalMinimumBid;

        // determining when the auction is ending automatically
        // endAt = block.timestamp + 1 days;
        emit Start(started, ended, nftId);
    }

    /**
     * @dev establish the minimum of ether to bid
     */
    function nextMinimumBid() public view returns (uint256) {
        uint256 _nextminbid = highestBid + additionalMinimumBid;
        return (_nextminbid);
    }

    /**
     * @dev enable bidding on the final selling price
     */
    function placeBid() external payable notOwner afterStart beforeEnd {
        require(msg.sender != admin, "Admin can't take part of this!");
        require(started == true, "Auction needs to start first!");
        require(ended == false, "Auction needs to start first!");
        require(msg.value >= startingPrice, "The starting bid is too low!");
        require(
            msg.value >= (highestBid + additionalMinimumBid),
            "The bid is too low!"
        );

        // currentBidofBidder is his old bids + his current bid
        // if his old bids = 0, then his current bid is equal to msg.value
        uint256 currentBidofBidder = msg.value;

        // send back the bid of the Outbidded
        if (highestBidder != address(0)) {
            uint256 balanceOutbidded = highestBid;
            (bool sent, ) = payable(highestBidder).call{
                value: balanceOutbidded
            }("");
            require(sent, "Could not send back the bid of the Outbidded.");
        }

        // update of highest Bid and highest Bidder
        highestBid = currentBidofBidder;
        highestBidder = payable(msg.sender);

        // add the Bidder to the daily player's list
        dailyPlayers.push(payable(highestBidder));
        // add the Bidder to a temporary daily player's list TO PUSH ON monthly list
        pushBidderInMGA(payable(highestBidder));

        emit PlaceBid(highestBidder, highestBid);
    }

    /**
     * @dev ending the auction, sending the nft to auction winner,
     */
    function endAuction() external payable {
        require(msg.sender == admin);
        require(started == true, "You need to start the Auction!");
        require(ended == false, "Auction already ended!");
        require(block.timestamp >= endAt, "Auction is still ongoing!"); // don't want to allow the Auction if the endAt time is not yet reached

        // ending the auction
        started = false;
        ended = true;

        if (highestBidder != address(0)) {
            // if there ARE bidder, nft goes to highest bidder
            nft.transferFrom(address(this), highestBidder, nftId);
        } else {
            // if there are NO bidder, nft goes to admin
            nft.transferFrom(address(this), adminPersonalAddress, nftId);
        }

        pushWinnerAuctionInMGA(payable(highestBidder));

        emit End(highestBidder, highestBid, started, ended);
    }

    // REQUEST RANDOMWORDS FCT

    /**
     * @dev generates random int *WARNING* -> Not safe for public use, vulnerbility detected ==> needs to change into Chainlink VRF
     * NOTE: the daily minter cannot win the daily price: last require in function below
     */
    function randomDailyWinner() public {
        require(msg.sender == admin);
        require(started == false, "Started is true!");
        require(ended == true, "Ended is false!");
        /*uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    dailyPlayers.length
                )
            )
        );
        dailyWinner = dailyPlayers[randomNumber % dailyPlayers.length];*/

        // VERIFIED RANDOMNESS WITH CHAINLINK_VRF
        dailyWinner = dailyPlayers[
            s_randomWords[0] % dailyPlayers.length
            //vrf.getS_randomWords()[0] % dailyPlayers.length
        ];

        require(
            dailyWinner != highestBidder,
            "The daily Winner cannot win the Daily Giveaway!"
        );

        emit RandomWinnerSelected(dailyWinner);
    }

    /**
     * @dev resets the giveaways
     */
    function resetDailyGiveaway() public {
        require(msg.sender == admin);
        dailyPlayers = new address payable[](0);
        emit DailyBidderReset(true);
    }

    /**
     * @dev picks a winner from the giveaway, and grants winner the balance of contract
     */
    function sendRewardsDailyWinner() public payable {
        require(msg.sender == admin);
        //makes sure that we have enough players in the giveaway
        require(started == false, "Started is true!");
        require(ended == true, "Ended is flase!");

        // sending the funds to the daily Winner
        dailyReward = (highestBid * percentageDailyWinner) / 100;
        (bool succes_dailyWinner, ) = payable(dailyWinner).call{
            value: dailyReward
        }("");
        require(
            succes_dailyWinner,
            "Could not transfer Giveaway to daily winner."
        );
        emit DailyReward(dailyReward);
        // sending funds to developpers
        (bool succes_dev, ) = payable(adminPersonalAddress).call{
            value: (highestBid * percentageDeveloppers) / 100
        }("");
        require(succes_dev, "Could not transfer funds to developpers.");

        // resets the players array once someone is picked
        dailyPlayers = new address payable[](0);
        resetDailyGiveaway();

        // send all funds of DGA contract to the MGA contract
        uint256 fundsToSendToMGA = address(this).balance;
        (bool succes_fundstoMGA, ) = payable(addressMGA).call{
            value: fundsToSendToMGA
        }("");
        require(succes_fundstoMGA, "Could not transfer balance to MGA.");
        emit DailyRemainToMGA(fundsToSendToMGA);
    }

    // adds an address to the monthly giveaway list
    function pushBidderInMGA(address _addressBidderToPushInMGA) public {
        mga.pushingDailyPlayersToMonthlyPlayerList(_addressBidderToPushInMGA);
    }

    // adds an address to the monthly giveaway of the winners of daily auctions
    function pushWinnerAuctionInMGA(address _addressWinnerAuctionToPushInMGA)
        public
    {
        mga.pushingWinnerAuctionToMonthlyPlayerList(
            _addressWinnerAuctionToPushInMGA
        );
    }

    function setForceTerminateAuction() public {
        require(started == true, "Started == true");
        require(ended == false, "Ended == false");

        started = false;
        ended = true;

        emit AuctionForceEnd(started, ended);
    }

    function forceSendNFT(address _toAddr) public {
        require(msg.sender == admin, "You need to be an admin");

        nft.transferFrom(address(this), payable(_toAddr), nftId);

        emit NftforceSent(true);
    }

    function setAdminPersonaAddress(address newAdminAddr) internal {
        adminPersonalAddress = payable(newAdminAddr);
    }

    /*
    // FOR KEEPERCHAINLINK
    function checkUpkeep(bytes calldata /* checkData ) external view override returns (bool upkeepNeeded, bytes memory /* performData ) {
        upkeepNeeded = (block.timestamp - startLastTimeStamp) > interval;
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    // FOR KEEPERCHAINLINK
    function performUpkeep(bytes calldata /* performData ) external override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        if ((block.timestamp - startLastTimeStamp) > interval ) {
            startLastTimeStamp = block.timestamp;
            
            startAuction();
        }
        if ((block.timestamp - endLastTimeStamp) > interval ) {
            endLastTimeStamp = block.timestamp;
            
            endAuction();
        }

        if ((block.timestamp - endLastTimeStamp) > 900000 ) {
            endLastTimeStamp = block.timestamp;
            
            endAuction();
        }
        // We don't use the performData in this example. The performData is generated by the Keeper's call to your checkUpkeep function
    }*/

    //@notice makes sure the owner CANT use the function
    modifier notOwner() {
        require(msg.sender != admin, "The owner can' take part");
        _;
    }

    modifier onlyHighestBidder() {
        require(
            msg.sender == highestBidder,
            "Only the winner of the Auction can claim the NFT!"
        );
        _;
    }

    //@notice makes sure the auction has already started
    modifier afterStart() {
        require(started == true, "Auction didn't start!");
        _;
    }

    //@notice before the auction ends
    modifier beforeEnd() {
        require(ended == false, "Auction already ended!");
        _;
    }
}
