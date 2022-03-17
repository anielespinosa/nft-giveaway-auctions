// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./VRFv2Consumer.sol";

contract FuckTheWhat is ERC721, VRFv2Consumer {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public baseURI =
        "https://gateway.pinata.cloud/ipfs/QmUCK1w1aei6B7nuScKmNrPpPJwDpxpkNZL2cfVaYohFHx/";
    string public baseExtension = ".json";

    bool public startedYearly;
    bool public endedYearly;

    address public admin;
    address public yearlyWinner;

    VRFv2Consumer vrf;

    constructor(uint64 _subscriptionId)
        ERC721("FuckTheWhat", "FTW")
        VRFv2Consumer(_subscriptionId)
    {
        admin = msg.sender;
    }

    receive() external payable {}

    function sendNFTto(address _addr) public onlyOwner returns (uint256) {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(_addr, newItemId);
        //_setTokenURI(newItemId, tokenURI);

        return newItemId;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistant token"
        );
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function randomYearlyWinner() public onlyOwner {
        require(startedYearly == false, "startedYearly == true");
        require(endedYearly == true, "endedYearly == false");

        //yearlyWinner = payable(ownerOf(randomNumber(366, block.difficulty, getBalance())));
        // MODULO of 366 for all daily winners of auction have a chance to win even the last one
        //uint256 nftId = s_randomWords[0] % 366;
        // FOR NOW modulo of 4 to chose from
        uint256 nftId = s_randomWords()[0] % 4;
        yearlyWinner = payable(ownerOf(nftId));
        (bool sent_yearlyWinner, ) = payable(yearlyWinner).call{
            value: getBalance()
        }("");
        require(sent_yearlyWinner, "Yearly fund sent to Winner.");
    }

    function getBalance() public view virtual returns (uint256) {
        // returns the contract balance
        return address(this).balance;
    }

    function setBaseURI(string memory _baseURI_) public onlyOwner {
        baseURI = _baseURI_;
    }

    function setBaseExtension(string memory _baseExtension) public onlyOwner {
        baseExtension = _baseExtension;
    }

    modifier onlyOwner() {
        require(msg.sender == admin, "You need to be the owner for this.");
        _;
    }
}
