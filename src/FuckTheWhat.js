import React from "react";
import { useEffect, useState } from "react";
import {
  dgaContract,
  connectWallet,
  sendNFTfromNFTCtoDGAC,
  setApprovalForAll,
  updateStartAuction,
  loadStartAuction,
  placeBid,
  updateEndAuction,
  selectDailyWinner,
  forceEndPressed,
  loadEndAuction,
  loadAdditionalMinimumBid,
  requestRandomWords,
  //loadOutbidded,
  //loadOutbiddedAddr,
  getCurrentWalletConnected,
  loadCurrentHighestBidderStatus,
  loadCurrentHighestBidStatus,
  loadDailyWinner,
  sendRewardsDailyWinner,
  web3
} from "./util/interact.js";

import alchemylogo from "./alchemylogo.svg";

const PUBLIC_KEY = "0xb32055E843EfDeFb612F0682a5020d3Ad4C32F12";
const blockNumberContractCreated = 10333522;

const FuckTheWhat = () => {
  //state variables
  const [walletAddress, setWallet] = useState("");
  const [status, setStatus] = useState("");
  const [started, setStarted] = useState(false);
  const [ended, setEnded] = useState(true);
  const [highestBidderDGA, setHighestBidderDGA] = useState("");
  const [highestBidDGA, setHighestBidDGA] = useState("");
  const [dailyWinner, setDailyWinner] = useState([]);
  const [outbids3, setOutbids3] = useState([]);
  const [outbids2, setOutbids2] = useState([]);
  const [outbids1, setOutbids1] = useState([]);
  const [outbidsAddr3, setOutbidsAddr3] = useState([]);
  const [outbidsAddr2, setOutbidsAddr2] = useState([]);
  const [outbidsAddr1, setOutbidsAddr1] = useState([]);
  const [numOutbidded, setNumOutbidded] = useState(0);
  const [addMinBid, setAddMinBid] = useState(0.00001);

  //called only once
  useEffect(async () => {
    const started = await loadStartAuction();
    const ended = await loadEndAuction();
    const highestBidderDGA = await loadCurrentHighestBidderStatus();
    const highestBidDGA = await loadCurrentHighestBidStatus();
    const addMinBid = await loadAdditionalMinimumBid();
    setStarted(started);
    setEnded(ended);
    setHighestBidderDGA(highestBidderDGA);
    setHighestBidDGA(highestBidDGA);
    setDailyWinner(dailyWinner);
    setAddMinBid(addMinBid);

    async function fetchStartEndStatus() {
      const _started = await loadStartAuction();
      const _ended = await loadEndAuction();
      setStarted(_started);
      setEnded(_ended);
    }
    fetchStartEndStatus();
    eventStartListener();

    async function fetchEndStartStatus() {
      const _started = await loadStartAuction();
      const _ended = await loadEndAuction();
      setStarted(_started);
      setEnded(_ended);
    }
    fetchEndStartStatus();
    eventEndListener();

    async function fetchUpdateDashboardStatus() {
      const _highestBidder = await loadCurrentHighestBidderStatus();
      const _highestBid = await loadCurrentHighestBidStatus();
      setHighestBidderDGA(_highestBidder);
      setHighestBidDGA(_highestBid);

      // HighestBid amount update 
      dgaContract.getPastEvents('PlaceBid', { fromBlock: blockNumberContractCreated }, function (error, events) {
        if (error) {
          console.log("Error fetchOutbidded getPastEvents " + error.message);
        } else if (events.length >= 3) {
          setOutbids3((events[events.length - 2].returnValues[1] * 10 ** (-18)).toFixed(5));
          setOutbids2((events[events.length - 3].returnValues[1] * 10 ** (-18)).toFixed(5));
          setOutbids1((events[events.length - 4].returnValues[1] * 10 ** (-18)).toFixed(5));
          setNumOutbidded(3);
        } else if (events.length == 2) {
          setOutbids3((events[events.length - 2].returnValues[1] * 10 ** (-18)).toFixed(5));
          setOutbids2((events[events.length - 3].returnValues[1] * 10 ** (-18)).toFixed(5));
          setNumOutbidded(events.length);
        } else if (events.length == 1) {
          setOutbids3((events[events.length - 2].returnValues[1] * 10 ** (-18)).toFixed(5));
          setNumOutbidded(events.length);
        }
      });

      // HighestBidder addresses update
      dgaContract.getPastEvents('PlaceBid', { fromBlock: blockNumberContractCreated }, function (error, events) {
        if (error) {
          console.log("Error fetchOutbiddedAddr getPastEvents " + error.message);
        } else if (events.length >= 3) {
          setOutbidsAddr3(events[events.length - 2].returnValues[0]);
          setOutbidsAddr2(events[events.length - 3].returnValues[0]);
          setOutbidsAddr1(events[events.length - 4].returnValues[0]);
          setNumOutbidded(3);
        } else if (events.length == 2) {
          setOutbidsAddr3(events[events.length - 2].returnValues[0]);
          setOutbidsAddr2(events[events.length - 3].returnValues[0]);
          setNumOutbidded(events.length);
        } else if (events.length == 1) {
          setOutbidsAddr3(events[events.length - 2].returnValues[0]);
          setNumOutbidded(events.length);
        }
      });
    }
    fetchUpdateDashboardStatus();
    eventsUpdateDashboardStatus();

    async function fetchDailyWinner() {
      const _dailyWinner = await loadDailyWinner();
      setDailyWinner(_dailyWinner);
      console.log("fetchDailyWinner _dailyWinner " + _dailyWinner);
    }
    fetchDailyWinner();
    eventRandomWinnerSelected();

    const { address, status } = await getCurrentWalletConnected();

    setWallet(address);
    setStatus(status);

    addWalletListener();
  }, []);

  function eventsUpdateDashboardStatus() {
    // HighestBidder and HighestBid updates dashboard
    dgaContract.events.PlaceBid({}, (error, data) => {
      if (error) {
        console.log("Error eventsUpdateDashboardStatus PlaceBid: " + error.message);
      } else {
        setHighestBidderDGA(data.returnValues[0]);
        setHighestBidDGA(data.returnValues[1]);
      }
    });

    // Outbidded addresses
    dgaContract.getPastEvents('PlaceBid', { fromBlock: blockNumberContractCreated }, function (error, events) {
      if (error) {
        console.log("Error eventsUpdateDashboardStatus getPastEvents " + error.message);
      } else if (numOutbidded >= 3) {
        setOutbidsAddr3(events[events.length - 2].returnValues[0]);
        setOutbidsAddr2(events[events.length - 3].returnValues[0]);
        setOutbidsAddr1(events[events.length - 4].returnValues[0]);
        setNumOutbidded(3);
      } else if (numOutbidded == 2) {
        setOutbidsAddr3(events[events.length - 2].returnValues[0]);
        setOutbidsAddr2(events[events.length - 3].returnValues[0]);
        setNumOutbidded(events.length);
      } else if (numOutbidded == 1) {
        setOutbidsAddr3(events[events.length - 2].returnValues[0]);
        setNumOutbidded(events.length);
      }
    });

    // Outbidded amounts
    dgaContract.getPastEvents('PlaceBid', { fromBlock: blockNumberContractCreated }, function (error, events) {
      if (error) {
        console.log("Error eventsUpdateDashboardStatus getPastEvents " + error.message);
      } else if (numOutbidded >= 3) {
        setOutbids3((events[events.length - 2].returnValues[1] * 10 ** (-18)).toFixed(5));
        setOutbids2((events[events.length - 3].returnValues[1] * 10 ** (-18)).toFixed(5));
        setOutbids1((events[events.length - 4].returnValues[1] * 10 ** (-18)).toFixed(5));
      } else if (numOutbidded == 2) {
        setOutbids3((events[events.length - 2].returnValues[1] * 10 ** (-18)).toFixed(5));
        setOutbids2((events[events.length - 3].returnValues[1] * 10 ** (-18)).toFixed(5));
      } else if (numOutbidded == 1) {
        setOutbids3((events[events.length - 2].returnValues[1] * 10 ** (-18)).toFixed(5));
      }
    });
  }

  function eventStartListener() {
    dgaContract.events.Start({}, (error, data) => {
      if (error) {
        setStatus("😥 " + error.message);
      } else {
        setStarted(data.returnValues[0]);
        setEnded(data.returnValues[1]);
      }
    });
  }

  function eventEndListener() {
    dgaContract.events.End({}, (error, data) => {
      if (error) {
        setStatus("😥 " + error.message);
      } else {
        setStarted(data.returnValues[2]);
        setEnded(data.returnValues[3]);
      }
    });
  }

  function eventRandomWinnerSelected() {
    dgaContract.events.RandomWinnerSelected({}, (error, data) => {
      if (error) {
        setStatus("😥 " + error.message);
      } else {
        setDailyWinner(data.returnValues[0]);
      }
    });
  }

  function addWalletListener() {
    if (window.ethereum) {
      window.ethereum.on("accountsChanged", (accounts) => {
        if (accounts.length > 0) {
          setWallet(accounts[0]);
          setStatus("👆🏽 Write a message in the text-field above.");
        } else {
          setWallet("");
          setStatus("🦊 Connect to Metamask using the top right button.");
        }
      });
    } else {
      setStatus(
        <p>
          {" "}
          🦊{" "}
          <a target="_blank" href={`https://metamask.io/download.html`}>
            You must install Metamask, a virtual Ethereum wallet, in your
            browser.
          </a>
        </p>
      );
    }
  }

  const connectWalletPressed = async () => {
    const walletResponse = await connectWallet();
    setStatus(walletResponse.status);
    setWallet(walletResponse.address);
  };

  const onSetApprovalForAllPressed = async () => {
    await setApprovalForAll(walletAddress);
  }

  const onSendNFTtoDGACPressed = async () => {
    await sendNFTfromNFTCtoDGAC(walletAddress);
  }

  const onStartAuctionPressed = async () => {
    await updateStartAuction(walletAddress);
    const _started = await loadStartAuction();
    const _ended = await loadEndAuction();
    setStarted(_started);
    setEnded(_ended);
    setNumOutbidded(0);
    console.log("Start is pressed");
  }

  const onPlaceBidPressed = async (e) => {
    e.preventDefault();
    const data = new FormData(e.target);
    await placeBid(walletAddress, data.get("amount"));
    eventsUpdateDashboardStatus();
    Outbidded();
    const _numOutbidded = numOutbidded + 1;
    setNumOutbidded(_numOutbidded);
  }

  const onEndAuctionPressed = async () => {
    await updateEndAuction(walletAddress);
    const _started = await loadStartAuction();
    const _ended = await loadEndAuction();
    setStarted(_started);
    setEnded(_ended);
  }

  const onForceEndPressed = async () => {
    await forceEndPressed(walletAddress);
    const _started = await loadStartAuction();
    const _ended = await loadEndAuction();
    setStarted(_started);
    setEnded(_ended);
    console.log("Force End is pressed");
  }

  const onSelectDailyWinnerPressed = async () => {
    const _dailyWinner = await selectDailyWinner(walletAddress);
    console.log("onSelectDailyWinnerPressed _dailyWinner" + _dailyWinner);
  }

  const onSendRewardsToDailyWinnerPressed = async () => {
    await sendRewardsDailyWinner(walletAddress, 0);
  }

  const onRequestRandomWordsVRFPressed = async () => {
    const _vrf = await requestRandomWords(walletAddress);
    console.log("please no" + _vrf);
  }

  function Outbidded(props) {
    if (numOutbidded == 1) {
      return <ReturnOutbidded3 />;
    } else if (numOutbidded == 2) {
      return <ReturnOutbidded2 />;
    } else if (numOutbidded >= 3) {
      return <ReturnOutbidded1 />;
    } else {
      return "";
    }
  }

  function ReturnOutbidded3(props) {
    return (
      <ul>
        <li>
          <div id="recent-bid-info">
            <div id="old-bid-addr">
              <p>{String(outbidsAddr3).substring(0, 5) + "..." + String(outbidsAddr3).substring(38)}</p>
            </div>
            <div id="old-bid-amount">
              <p>Ξ {outbids3}</p>
            </div>
            <div id="old-bid-link">
              <p>link to transaction</p>
            </div>
          </div>
        </li>
      </ul>
    );
  }

  function ReturnOutbidded2(props) {
    return (
      <ul>
        <li>
          <div id="recent-bid-info">
            <div id="old-bid-addr">
              <p>{String(outbidsAddr3).substring(0, 5) + "..." + String(outbidsAddr3).substring(38)}</p>
            </div>
            <div id="old-bid-amount">
              <p>Ξ {outbids3}</p>
            </div>
            <div id="old-bid-link">
              <p>link to transaction</p>
            </div>
          </div>
        </li>
        <li>
          <div id="recent-bid-info">
            <div id="old-bid-addr">
              <p>{String(outbidsAddr2).substring(0, 5) + "..." + String(outbidsAddr2).substring(38)}</p>
            </div>
            <div id="old-bid-amount">
              <p>Ξ {outbids2}</p>
            </div>
            <div id="old-bid-link">
              <p>link to transaction</p>
            </div>
          </div>
        </li>
      </ul>
    );
  }

  function ReturnOutbidded1(props) {
    return (
      <ul>
        <li>
          <div id="recent-bid-info">
            <div id="old-bid-addr">
              <p>{String(outbidsAddr3).substring(0, 5) + "..." + String(outbidsAddr3).substring(38)}</p>
            </div>
            <div id="old-bid-amount">
              <p>Ξ {outbids3}</p>
            </div>
            <div id="old-bid-link">
              <p>link to transaction</p>
            </div>
          </div>
        </li>
        <li>
          <div id="recent-bid-info">
            <div id="old-bid-addr">
              <p>{String(outbidsAddr2).substring(0, 5) + "..." + String(outbidsAddr2).substring(38)}</p>
            </div>
            <div id="old-bid-amount">
              <p>Ξ {outbids2}</p>
            </div>
            <div id="old-bid-link">
              <p>link to transaction</p>
            </div>
          </div>
        </li>
        <li>
          <div id="recent-bid-info">
            <div id="old-bid-addr">
              <p>{String(outbidsAddr1).substring(0, 5) + "..." + String(outbidsAddr1).substring(38)}</p>
            </div>
            <div id="old-bid-amount">
              <p>Ξ {outbids1}</p>
            </div>
            <div id="old-bid-link">
              <p>link to transaction</p>
            </div>
          </div>
        </li>
      </ul>
    );
  }

  function AdminGreeting(props) {
    return <div id="dashboard-admin-top">
      <div id="StartEndStatus">
        <div id="StartStatus">
          <h2 style={{ paddingTop: "5px" }}>Current Started Status:</h2>
          <p>{String(started)}</p>
        </div>
        <div id="EndStatus">
          <h2 style={{ paddingTop: "5px" }}>Current Ended Status:</h2>
          <p>{String(ended)}</p>
        </div>
      </div>
      <div className="dashboard-admin-button">
        <div id="mini-button-container">
          <button id="publish" onClick={onSetApprovalForAllPressed}>
            Set Approval for DGA contract
          </button>
          <button id="publish" onClick={onSendNFTtoDGACPressed}>
            Send NFT to DGAC
          </button>
          <button id="publish" onClick={onStartAuctionPressed}>
            Start Auction
          </button>
          <button id="publish" onClick={onEndAuctionPressed}>
            End Auction
          </button>
        </div>
        <div id="mini-button-container">
          <button id="publish" onClick={onForceEndPressed}>
            Force stop Auction
          </button>
          <button id="publish" onClick={onRequestRandomWordsVRFPressed}>
            Request Random Words
          </button>
          <button id="publish" onClick={onSelectDailyWinnerPressed}>
            Select daily winner
          </button>
          <button id="publish" onClick={onSendRewardsToDailyWinnerPressed}>
            Send rewards to daily winner
          </button>
        </div>
      </div>
    </div>;
  }

  function Admin(props) {
    if (String(walletAddress).toLowerCase() === String(PUBLIC_KEY).toLowerCase()) {
      return <AdminGreeting />;
    }
    return "";
  }

  //the UI of our component
  return (
    <div id="header">
      <div id="top-header">
        <img id="logo" src={alchemylogo}></img>
        <button id="walletButton" onClick={connectWalletPressed}>
          {walletAddress.length > 0 ? (
            "Connected: " +
            String(walletAddress).substring(0, 5) +
            "..." +
            String(walletAddress).substring(38)
          ) : (
            <span>Connect Wallet</span>
          )}
        </button>
      </div>
      <Admin />
      <div id="dashboard-container">
        <div id="img-auctioned">
          <img id="auctioned-img" src={"https://gateway.pinata.cloud/ipfs/QmUCK1w1aei6B7nuScKmNrPpPJwDpxpkNZL2cfVaYohFHx/1.png"} alt="Auctioned Image" />
        </div>
        <div id="dashboard">
          <div id="title-auction">
            <p id="title">FTW 1</p>
          </div>
          <div id="info-bid">
            <div id="winning-bid">
              <h2 style={{ paddingTop: "0px" }}>Current Highest Bid:</h2>
              <p>{String((highestBidDGA * 10 ** (-18)).toFixed(5))}</p>
            </div>
            <div id="winning-address">
              <h2 style={{ paddingTop: "0px" }}>Current Highest Bidder:</h2>
              <p>{String(highestBidderDGA).substring(0, 5) + "..." + String(highestBidderDGA).substring(38)}</p>
            </div>
          </div>
          <div id="place-bid">
            <div id="next-minimum-bid-info">
              <h2 style={{ paddingTop: "0px" }}>Next Minimum Bid:</h2>
              <p>{String((((highestBidDGA * 10 ** (-18)) + 0.00001)).toFixed(5))}</p>
            </div>
            <div id="input-bid-block">
              <form onSubmit={onPlaceBidPressed}>
                <div className="my-3">
                  <input
                    type="text"
                    name="amount"
                    placeholder="Your bid here"
                  />
                </div>
                <footer className="p-4">
                  <button type="submit">
                    Place Bid
                  </button>
                </footer>
              </form>
            </div>
          </div>
          <div id="recent-bids">
            <ul>
              <p>Outbidded</p>
              <Outbidded />
            </ul>
          </div>
        </div>
      </div>
      <div id="daily-winner-infos">
        <p>Daily Winner : {dailyWinner}</p>
      </div>
      <div id="smart-contracts-info">
        <p>FTWC address: 0x6E51d75802A1C74b1e891f4dFf0B51FFb003ae0B </p>
        <p>DGAC address: 0x60bdAa4Ec4896281e4dd8c84872492F7E95A5a3f </p>
      </div>
    </div>
  );

};



export default FuckTheWhat;
