var lotto;

function secondsToHms(d) {
    d = Number(d);
    var h = Math.floor(d / 3600);
    var m = Math.floor(d % 3600 / 60);
    var s = Math.floor(d % 3600 % 60);

    var hDisplay = h > 0 ? h + (h == 1 ? " hour, " : " hours, ") : "";
    var mDisplay = m > 0 ? m + (m == 1 ? " minute, " : " minutes, ") : "";
    var sDisplay = s > 0 ? s + (s == 1 ? " second" : " seconds") : "";
    return hDisplay + mDisplay + sDisplay;
}

function convert() {
    document.querySelector("#buyInput").value = parseInt(document.querySelector("#buyInput").value);
    if (document.querySelector("#buyInput").value == "NaN") {
        document.querySelector("#buyInput").value = 0;
    }
    document.querySelector("#conversion").innerHTML = "= " + ethers.utils.formatEther(document.querySelector("#buyInput").value) + " Ethereum";
}

function startUpdating() {
    if (window.document.hasFocus()) {
        signer.getAddress().then((addy) => {
            document.querySelector("#address").innerHTML = addy;
            lotto.accumulatedEther(addy).then((accume) => {
                document.querySelector("#pAllTime").innerHTML = accume;
            });
            lotto.ethAvailable(addy).then((avail) => {
                document.querySelector("#ethAvailable").innerHTML = avail;
            });
        });
        provider
            .getBalance("0x4828bf2835ccDDBb371adc15ed7a00c2b86CC69A")
            .then((bal) => {
                document.querySelector("#pot").innerHTML = "pot is " +
                    ethers.utils.formatEther(bal);
            });
        lotto.allTimeWinnings().then((win) => {
            document.querySelector("#allTime").innerHTML = "all time winnings " + win;
        });
        provider.getBlockNumber().then((block) => {
            lotto.endingBlock().then((end) => {
                document.querySelector("#blocks").innerHTML = "blocks " + (end - block);
                document.querySelector("#time").innerHTML = "Time Left ~" + secondsToHms(Math.abs(end - block) * 13.87);
            });
        });
        setTimeout(startUpdating, 12.57 * 1000);
    }
}

window.addEventListener("load", function () {
    if (typeof window.ethereum === "undefined") {
        document.querySelector("#connect").innerHTML = "Requires MetaMask";
        document.querySelector("#connect").style.background = "yellow";
        document.querySelector("#mask").style.display = "block";
        console.log("nooooo");
    } else {
        lotto = getLottoInfo(true);
        colorStuff();
        startUpdating();
    }
});



async function switchChains() {
    try {
        await ethereum.request({
            method: "wallet_switchEthereumChain",
            params: [{ chainId: "0x2a" }],
        });
    } catch (switchError) {
        // This error code indicates that the chain has not been added to MetaMask.
        if (switchError.code === 4902) {
            try {
                await ethereum.request({
                    method: "wallet_addEthereumChain",
                    params: [
                        {
                            chainId: "0x2a",
                            chainName: "Kovan Test Network",
                            rpcUrls: ["https://kovan.infura.io/v3/"],
                        },
                    ],
                });
            } catch (addError) {
                // handle "add" error
            }
        }
        // handle other "switch" errors
    }

    await ethereum.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: "0x2a" }],
    });
}

function colorStuff() {
    if (typeof window.ethereum !== "undefined") {
        console.log("MetaMask is installed!");
        if (ethereum.selectedAddress === null) {
            document.querySelector("#connect").style.background = "";
            document.querySelector("#connect").innerHTML =
                "Connect to MetaMask";
        } else if (ethereum.chainId != "0x2a") {
            document.querySelector("#connect").innerHTML = "Switch to Kovan";
        } else {
            document.querySelector("#connect").style.background = "lightgreen";
            document.querySelector("#connect").innerHTML =
                "Connected to MetaMask!";
        }
    }
}

ethereum.on("accountsChanged", function () {
    window.location.reload();
});

ethereum.on("chainChanged", function () {
    window.location.reload();
});

const ethereumButton = document.querySelector("#connect");

// A Web3Provider wraps a standard Web3 provider, which is
// what MetaMask injects as window.ethereum into each page
const provider = new ethers.providers.Web3Provider(window.ethereum);

ethereumButton.addEventListener("click", () => {
    // ethereum.request({ method: "eth_requestAccounts" });
    provider.send("eth_requestAccounts", []);
    switchChains();
});

const signer = provider.getSigner();

const buyButton = document.querySelector("#buyButton");

buyButton.addEventListener("click", () => {
    // ethereum.request({ method: "eth_requestAccounts" });
    lotto.buyTickets({ value: document.querySelector("#buyInput").value });
});

const startButton = document.querySelector("#start");

startButton.addEventListener("click", () => {
    lotto.start();
});

const stake = document.querySelector("#stake");

stake.addEventListener("click", () => {
    lotto.enableRewards();
});

const payout = document.querySelector("#payout");

payout.addEventListener("click", () => {
    lotto.payout();
});

const withdraw = document.querySelector("#withdraw");

withdraw.addEventListener("click", () => {
    signer.getAddress().then((addy) => {
        lotto.withdraw(addy);
    });
});


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

function hexify(utf) {
    let yo = utf
        .split("")
        .map((c) => c.charCodeAt(0).toString(16).padStart(2, "0"))
        .join("");

    return "0x" + yo;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

// A Human-Readable ABI; for interacting with the contract, we
// must include any fragment we wish to use
const abi = [
    // Read-Only Functions
    "function accumulatedEther(address account) view returns (uint256)",
    "function allTimeWinnings() view returns (uint256)",
    "function areRewardsEnabled(address account) view returns (bool)",
    "function endingBlock() view returns (uint256)",
    "function ethAvailable(address account) view returns (uint256)",

    // Authenticated Functions
    "function buyTickets() payable",
    "function enableRewards()",
    "function payout()",
    "function start()",
    "function withdraw(address account)",

    // Events
    "event Payout(address winner, uint256 id, uint256 value)",
];

function getLottoInfo(write) {
    // This can be an address or an ENS name
    let address = "0x4828bf2835ccDDBb371adc15ed7a00c2b86CC69A";

    if (!write) {
        // Read-Only; By connecting to a Provider, allows:
        // - Any constant function
        // - Querying Filters
        // - Populating Unsigned Transactions for non-constant methods
        // - Estimating Gas for non-constant (as an anonymous sender)
        // - Static Calling non-constant methods (as anonymous sender)
        return new ethers.Contract(address, abi, provider);
    } else {
        // Read-Write; By connecting to a Signer, allows:
        // - Everything from Read-Only (except as Signer, not anonymous)
        // - Sending transactions for non-constant functions
        return new ethers.Contract(address, abi, signer);
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

// const sendTokenButton = document.querySelector("#sendTokenButton");

//Sending Dai to an address
// sendTokenButton.addEventListener("click", async () => {
//     const erc20_rw = getTokenInfo(true);
//     const tx = await erc20_rw
//         .transfer(
//             await provider.resolveName(
//                 document.querySelector("#toToken").value
//             ),
//             ethers.utils.parseUnits(
//                 document.querySelector("#token").value,
//                 await erc20_rw.decimals()
//             )
//         )
//         .then((txHash) => {
//             document.querySelector("#sendToken").innerHTML = txHash.hash;
//             document.querySelector("#sendToken").style.display = "block";
//             document.querySelector("#sendToken").href =
//                 "https://kovan.etherscan.io/tx/" + txHash.hash;
//         })
//         .catch((error) => console.error);
// });
