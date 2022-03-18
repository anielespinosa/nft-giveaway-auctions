//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./YearlyGiveawayAuction.sol";
import "./VRFv2Consumer.sol";

abstract contract IMonthlyGiveawayAuction {
    function pushingDailyPlayersToMonthlyPlayerList(
        address[] memory _dailyPlayersList
    ) public virtual;

    function resetMonthlyGiveaway() internal virtual;

    function getMonthlyPlayer(uint256 index)
        public
        view
        virtual
        returns (address);

    function pushingDailyPlayersToMonthlyPlayerList(address _dailyPlayer)
        public
        virtual;

    function pushingWinnerAuctionToMonthlyPlayerList(
        address _dailyWinnerAuction
    ) public virtual;

    function getBalance() public view virtual returns (uint256);
}

/**
 * @title MonthlyGiveawayAuction
 * @dev Ether Giveaway that transfer contract amount to winner
 */
contract MonthlyGiveawayAuction is VRFv2Consumer {
    bool public startedMonthly;
    bool public endedMonthly;
    uint256 public endAtMonthly;

    //list of players registered in lotery
    address payable[] public monthlyPlayers;
    address payable[] public monthlyDailyWinnerAuction;
    address public admin;
    address payable monthlyWinnerBidder;
    address payable monthlyWinnerAuctionWinner;

    // public, private, internal or what?
    uint256 public OUROWNTOKENID;

    uint256 public percentageMonthlyWinner = 30;
    uint256 public percentageMonthlyBidders = 20;

    //mapping(address => uint256) public bids;

    // info for interaction with MonthlyGiveawayAuction Contract
    address payable addressNFT;

    VRFv2Consumer vrf;

    constructor(address _addressNFT, uint64 _subscriptionId)
        VRFv2Consumer(_subscriptionId)
    {
        admin = msg.sender;
        addressNFT = payable(_addressNFT);
        startedMonthly = false;
        endedMonthly = true;
    }

    receive() external payable {}

    function startMonthlyAuction() external onlyOwner {
        require(startedMonthly == false, "Auction already started!");
        require(endedMonthly == true, "Auction is ended!");
        require(msg.sender == admin, "You cannot start the Auction!");

        startedMonthly = true;
        endedMonthly = false;

        // determining when the auction is ending automatically
        // endAtMonthly = block.timestamp + 30 days;
    }

    function pushingDailyPlayersToMonthlyPlayerList(address _dailyPlayer)
        public
    {
        monthlyPlayers.push(payable(_dailyPlayer));
    }

    function pushingWinnerAuctionToMonthlyPlayerList(
        address _dailyWinnerAuction
    ) public {
        monthlyDailyWinnerAuction.push(payable(_dailyWinnerAuction));
    }

    /**
     * @dev ending the auction and calling the dailyGiveaway
     */
    function endMonthlyAuction() external onlyOwner {
        require(startedMonthly == true, "You need to start the Auction!");
        require(block.timestamp >= endAtMonthly, "Auction is still ongoing!"); // don't want to allow the Auction if the endAt time is not yet reached
        require(endedMonthly == false, "Auction already ended!");

        // ending the auction
        startedMonthly = false;
        endedMonthly = true;
    }

    /**
     * @dev generates random int *WARNING* -> Not safe for public use, vulnerbility detected ==> needs to change into Chainlink VRF
     * NOTE: the daily minter cannot win the daily price: last require in function below
     */
    function randomMonthlyWinner() public onlyOwner {
        require(startedMonthly == false, "Started is true!");
        require(endedMonthly == true, "Ended is flase!");

        // VERIFIED RANDOMNESS WITH CHAINLINK_VRF
        monthlyWinnerBidder = monthlyPlayers[
            s_randomWords[0] % monthlyPlayers.length
        ];
        monthlyWinnerAuctionWinner = monthlyDailyWinnerAuction[
            s_randomWords[1] % monthlyDailyWinnerAuction.length
        ];

        /*uint256 randomNumber1 = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    monthlyPlayers.length
                )
            )
        );
        uint256 randomNumber2 = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    monthlyDailyWinnerAuction.length
                )
            )
        );
        monthlyWinnerBidder = monthlyPlayers[
            randomNumber1 % monthlyPlayers.length
        ];
        monthlyWinnerAuctionWinner = monthlyDailyWinnerAuction[
            randomNumber2 % monthlyDailyWinnerAuction.length
        ];*/
    }

    /**
     * @dev picks a winner from the giveaway, and grants winner the balance of contract
     */
    function sendRewardsMonthlyWinner() public payable onlyOwner {
        //makes sure that we have enough players in the giveaway
        require(startedMonthly == false, "Started is true!");
        require(endedMonthly == true, "Ended is flase!");

        // sending the funds to the monthly Winner
        (bool succes_dailyWinner, ) = payable(monthlyWinnerBidder).call{
            value: (getBalance() * percentageMonthlyBidders) / 100
        }("");
        require(
            succes_dailyWinner,
            "Could not transfer Giveaway to daily winner."
        );
        (bool succes_dailyWinnerAuctionWinner, ) = payable(
            monthlyWinnerAuctionWinner
        ).call{value: (getBalance() * percentageMonthlyWinner) / 100}("");
        require(
            succes_dailyWinnerAuctionWinner,
            "Could not transfer Giveaway to daily winner."
        );

        // resets the players array once someone is picked
        resetMonthlyGiveaways();

        // send all funds of MGA contract to the YGA contract
        (bool succes_fundstoYGA, ) = payable(addressNFT).call{
            value: getBalance()
        }("");
        require(succes_fundstoYGA, "Could not transfer balance to MGA.");
    }

    /**
     * @dev resets the giveaways
     */
    function resetMonthlyGiveaways() internal onlyOwner {
        monthlyPlayers = new address payable[](0);
        monthlyDailyWinnerAuction = new address payable[](0);
    }

    function getBalance() public view virtual returns (uint256) {
        // returns the contract balance
        return address(this).balance;
    }

    //@notice makes sure the owner is the ONLY one that can use the function
    modifier onlyOwner() {
        require(admin == msg.sender, "You are not the owner");
        _;
    }
}
