const NETWORK_ID = 10;

const MY_CONTRACT_ADDRESS = "0x10445fff1600AD3e38276EE3ec7CF7625D852687";
const MY_CONTRACT_ABI_PATH = "./json_abi/LottoCeremony.json";
var my_contract;

var accounts;
var web3;

function metamaskReloadCallback() {
  window.ethereum.on("accountsChanged", (accounts) => {
    document.getElementById("web3_message").textContent =
      "Se cambió el account, refrescando...";
    window.location.reload();
  });
  window.ethereum.on("networkChanged", (accounts) => {
    document.getElementById("web3_message").textContent =
      "Se el network, refrescando...";
    window.location.reload();
  });
}

const getWeb3 = async () => {
  return new Promise((resolve, reject) => {
    if (document.readyState == "complete") {
      if (window.ethereum) {
        const web3 = new Web3(window.ethereum);
        window.location.reload();
        resolve(web3);
      } else {
        reject("must install MetaMask");
        document.getElementById("web3_message").textContent =
          "Error: Porfavor conéctate a Metamask";
      }
    } else {
      window.addEventListener("load", async () => {
        if (window.ethereum) {
          const web3 = new Web3(window.ethereum);
          resolve(web3);
        } else {
          reject("must install MetaMask");
          document.getElementById("web3_message").textContent =
            "Error: Please install Metamask";
        }
      });
    }
  });
};

const getContract = async (web3, address, abi_path) => {
  const response = await fetch(abi_path);
  const data = await response.json();

  const netId = await web3.eth.net.getId();
  contract = new web3.eth.Contract(data, address);
  return contract;
};

async function loadDapp() {
  metamaskReloadCallback();
  document.getElementById("web3_message").textContent =
    "Please connect to Metamask";
  var awaitWeb3 = async function () {
    web3 = await getWeb3();
    web3.eth.net.getId((err, netId) => {
      if (netId == NETWORK_ID) {
        var awaitContract = async function () {
          my_contract = await getContract(
            web3,
            MY_CONTRACT_ADDRESS,
            MY_CONTRACT_ABI_PATH
          );
          document.getElementById("web3_message").textContent =
            "You are connected to Metamask";
          onContractInitCallback();
          web3.eth.getAccounts(function (err, _accounts) {
            accounts = _accounts;
            if (err != null) {
              console.error("An error occurred: " + err);
            } else if (accounts.length > 0) {
              onWalletConnectedCallback();
              document.getElementById("account_address").style.display =
                "block";
            } else {
              document.getElementById("connect_button").style.display = "block";
            }
          });
        };
        awaitContract();
      } else {
        document.getElementById("web3_message").textContent =
          "Please connect to Optimism Mainnet";
      }
    });
  };
  awaitWeb3();
}

async function connectWallet() {
  await window.ethereum.request({ method: "eth_requestAccounts" });
  accounts = await web3.eth.getAccounts();
  onWalletConnectedCallback();
}

loadDapp();

const onContractInitCallback = async () => {
  var ceremonyCount = await my_contract.methods.ceremonyCount().call();
  document.getElementById("contract_state").textContent =
    "Ceremony count: " + ceremonyCount;
  /*
  var last_writer = await my_contract.methods.count().call()

  var contract_state = "Hello: " + hello
    + ", Count: " + count
    + ", Last Writer: " + last_writer
  
  */
};

const onWalletConnectedCallback = async () => {};

//// Queries ////

async function getCeremony(ceremonyIdGetCeremony) {
  var ceremony = await my_contract.methods
    .ceremonies(ceremonyIdGetCeremony)
    .call();
  //var winner = await my_contract.methods.getWinner(ceremonyIdGetCeremony).call()
  //var getRandomness = await my_contract.methods.getWinner(ceremonyIdGetCeremony).call()
  isClaimed = ceremony.isClaimed;
  ticketCount = ceremony.ticketCount;
  ticketPrice = ceremony.ticketPrice;
  stakeAmount = ceremony.stakeAmount;
  document.getElementById("get_ceremony_text").textContent =
    "isClaimed: " +
    isClaimed +
    " ticketCount: " +
    ticketCount +
    " ticketPrice: " +
    web3.utils.fromWei(ticketPrice) +
    " stakeAmount: " +
    web3.utils.fromWei(stakeAmount);
  //+ " winner: "+ winner
  //+ " getRandomness: "+ getRandomness
}

async function getTicket(ceremonyIdGetTicket, ticketIdGetTicket) {
  var ticketOwner = await my_contract.methods
    .tickets(ceremonyIdGetTicket, ticketIdGetTicket)
    .call();
  document.getElementById("get_ticket_text").textContent = ticketOwner;
}

async function getWinner(ceremonyIdGetWinner) {
  var winner0 = await my_contract.methods
    .getWinner(ceremonyIdGetWinner, 0)
    .call();
  var winner1 = await my_contract.methods
    .getWinner(ceremonyIdGetWinner, 1)
    .call();
  var winner2 = await my_contract.methods
    .getWinner(ceremonyIdGetWinner, 2)
    .call();
  console.log(winner0);
  console.log(winner1);
  console.log(winner2);
  var getRandomness = await my_contract.methods
    .getRandomness(ceremonyIdGetWinner)
    .call();

  console.log(getRandomness);

  document.getElementById("get_winner_text").textContent =
    " ETH Winner: " +
    winner0 +
    " NFT Winner: " +
    winner1 +
    " Has to pay beer: " +
    winner2 +
    " getRandomness: " +
    getRandomness;
}

//// Functions ////

const commit = async (ceremonyId, hashedValue) => {
  var ceremony = await my_contract.methods.ceremonies(ceremonyId).call();
  var ticketPrice = ceremony[6];
  var stakeAmount = ceremony[7];
  var valueSent = parseInt(ticketPrice) + parseInt(stakeAmount);

  const result = await my_contract.methods
    .commit(accounts[0], ceremonyId, hashedValue)
    .send({ from: accounts[0], gas: 0, value: valueSent })
    .on("transactionHash", function (hash) {
      document.getElementById("web3_message").textContent = "Executing...";
    })
    .on("receipt", function (receipt) {
      document.getElementById("web3_message").textContent = "Success.";
    })
    .catch((revertReason) => {
      console.log(
        "ERROR! Transaction reverted: " + revertReason.receipt.transactionHash
      );
    });
};

const reveal = async (ceremonyId, hashedValue, secretValue) => {
  const result = await my_contract.methods
    .reveal(ceremonyId, hashedValue, secretValue)
    .send({ from: accounts[0], gas: 0, value: 0 })
    .on("transactionHash", function (hash) {
      document.getElementById("web3_message").textContent = "Executing...";
    })
    .on("receipt", function (receipt) {
      document.getElementById("web3_message").textContent = "Success.";
    })
    .catch((revertReason) => {
      console.log(
        "ERROR! Transaction reverted: " + revertReason.receipt.transactionHash
      );
    });
};

const createCeremony = async (
  commitmentDeadline,
  revealDeadline,
  ticketPrice,
  stakeAmount,
  nftID,
  nftContractAddress,
  nftCreatorAddress,
  protocolAddress,
  nftCreatorETHPercentage,
  protocolETHPercentage
) => {
  const result = await my_contract.methods
    .createCeremony(
      commitmentDeadline,
      revealDeadline,
      ticketPrice,
      stakeAmount,
      nftID,
      nftContractAddress,
      nftCreatorAddress,
      protocolAddress,
      nftCreatorETHPercentage,
      protocolETHPercentage
    )
    .send({ from: accounts[0], gas: 0, value: 0 })
    .on("transactionHash", function (hash) {
      document.getElementById("web3_message").textContent = "Executing...";
    })
    .on("receipt", function (receipt) {
      document.getElementById("web3_message").textContent = "Success.";
    })
    .catch((revertReason) => {
      console.log(
        "ERROR! Transaction reverted: " + revertReason.receipt.transactionHash
      );
    });
};

const claimETH = async (ceremonyId) => {
  const result = await my_contract.methods
    .claimETH(ceremonyId)
    .send({ from: accounts[0], gas: 0, value: 0 })
    .on("transactionHash", function (hash) {
      document.getElementById("web3_message").textContent = "Executing...";
    })
    .on("receipt", function (receipt) {
      document.getElementById("web3_message").textContent = "Success.";
    })
    .catch((revertReason) => {
      console.log(
        "ERROR! Transaction reverted: " + revertReason.receipt.transactionHash
      );
    });
};

const claimNFTCreatorETH = async (ceremonyId) => {
  const result = await my_contract.methods
    .claimNFTCreatorETH(ceremonyId)
    .send({ from: accounts[0], gas: 0, value: 0 })
    .on("transactionHash", function (hash) {
      document.getElementById("web3_message").textContent = "Executing...";
    })
    .on("receipt", function (receipt) {
      document.getElementById("web3_message").textContent = "Success.";
    })
    .catch((revertReason) => {
      console.log(
        "ERROR! Transaction reverted: " + revertReason.receipt.transactionHash
      );
    });
};

const claimProtocolETH = async (ceremonyId) => {
  const result = await my_contract.methods
    .claimProtocolETH(ceremonyId)
    .send({ from: accounts[0], gas: 0, value: 0 })
    .on("transactionHash", function (hash) {
      document.getElementById("web3_message").textContent = "Executing...";
    })
    .on("receipt", function (receipt) {
      document.getElementById("web3_message").textContent = "Success.";
    })
    .catch((revertReason) => {
      console.log(
        "ERROR! Transaction reverted: " + revertReason.receipt.transactionHash
      );
    });
};

const claimNFT = async (ceremonyId) => {
  const result = await my_contract.methods
    .claimNFT(ceremonyId)
    .send({ from: accounts[0], gas: 0, value: 0 })
    .on("transactionHash", function (hash) {
      document.getElementById("web3_message").textContent = "Executing...";
    })
    .on("receipt", function (receipt) {
      document.getElementById("web3_message").textContent = "Success.";
    })
    .catch((revertReason) => {
      console.log(
        "ERROR! Transaction reverted: " + revertReason.receipt.transactionHash
      );
    });
};

const startTimerCommit = async (ceremonyId) => {
  var time = await my_contract.methods.getTimerCommit(ceremonyId);
  var initialTime = time * 60;
  console.log(time);
  var timerInterval; // Declare a variable to store the interval ID

  if (!timerInterval && initialTime > 0) {
    timerInterval = setInterval(function () {
      initialTime--;
      updateTimerDisplay(initialTime, "_timerCommit");

      if (initialTime <= 0) {
        clearInterval(timerInterval); // Stop the timer when it reaches 0
        timerInterval = null;
      }
    }, 1000);
  }
};

const startTimerReveal = async (ceremonyId) => {
  var time = await my_contract.methods.getTimerReveal(ceremonyId);
  var initialTime = time * 60;
  console.log(time);
  var timerInterval; // Declare a variable to store the interval ID

  if (!timerInterval && initialTime > 0) {
    timerInterval = setInterval(function () {
      initialTime--;
      updateTimerDisplay(initialTime, "_timerReveal");

      if (initialTime <= 0) {
        clearInterval(timerInterval); // Stop the timer when it reaches 0
        timerInterval = null;
      }
    }, 1000);
  }
};

function updateTimerDisplay(timeInSeconds, timerId) {
  var minutes = Math.floor(timeInSeconds / 60);
  var seconds = timeInSeconds % 60;

  // Format minutes and seconds to display as "mm:ss"
  var formattedTime =
    (minutes < 10 ? "0" : "") +
    minutes +
    ":" +
    (seconds < 10 ? "0" : "") +
    seconds;

  document.getElementById(timerId).textContent = formattedTime;
}
