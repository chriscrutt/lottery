var lotto;
var ethPrice;
var ethPriceChain;

// when page loads
window.addEventListener("load", function () {
    if (typeof window.ethereum === "undefined") {
        console.log("nooooo");
    } else {
        lotto = getLottoInfo(true);
        ethPrice = ethPriceOracle();
        ethPriceChain = ethPriceChain();
        colorStuff();
        startUpdating();
    }
});

// colors the "connected" menu item
function colorStuff() {
    if (typeof window.ethereum !== "undefined") {
        console.log("MetaMask is installed!");
        if (ethereum.selectedAddress != null) {
            if (ethereum.chainId != "0x2a") {
                document.querySelector("#connect").style.color = "sandybrown";
                document.querySelector("#connect").innerHTML = "Switch Network";
            } else {
                document.querySelector("#connect").style.color =
                    "mediumseagreen";
                document.querySelector("#connect").innerHTML = "Connected";
            }
        }
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// the sacred connect button
const ethereumButton = document.querySelector("#connect");

// A Web3Provider wraps a standard Web3 provider, which is
// what MetaMask injects as window.ethereum into each page
const provider = new ethers.providers.Web3Provider(window.ethereum);

const signer = provider.getSigner();

ethereumButton.addEventListener("click", () => {
    // ethereum.request({ method: "eth_requestAccounts" });
    provider.send("eth_requestAccounts", []);
    switchChains();
});

ethereum.on("accountsChanged", function () {
    window.location.reload();
});

ethereum.on("chainChanged", function () {
    window.location.reload();
});

// function to switch/add a chain
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

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

function convert() {
    document.querySelector("#ticketAmount").value = document.querySelector("#ticketAmount").value.replace(/\D/g,'');
    if (document.querySelector("#ticketAmount").value == "NaN") {
        document.querySelector("#ticketAmount").value = 0;
    }
    document.querySelector("#buyToEth").innerHTML = "Ξ " + ethers.utils.formatEther(document.querySelector("#ticketAmount").value);
    document.querySelector("#buyToUsd").innerHTML = "$ " + Math.round(ethers.utils.formatEther(document.querySelector("#ticketAmount").value) * ethPrice * 1e6) / 1e6;
}

function secondsToHms(d) {
    d = Number(d);
    var h = Math.floor(d / 3600);
    var m = Math.floor((d % 3600) / 60);
    var s = Math.floor((d % 3600) % 60);

    var hDisplay = h > 0 ? h + (h == 1 ? " hour, " : " hours, ") : "";
    var mDisplay = m > 0 ? m + (m == 1 ? " minute, " : " minutes, ") : "";
    var sDisplay = s > 0 ? s + (s == 1 ? " second" : " seconds") : "";
    return hDisplay + mDisplay + sDisplay;
}

function startUpdating() {
    if (window.document.hasFocus()) {
        // ethPrice.getRateToEth("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", true).then((rate) => {
        ethPriceChain.latestAnswer().then((rate) => {
            ethPrice = Math.round(1e18 / rate * 100) / 100;
            provider
                .getBalance("0x4828bf2835ccDDBb371adc15ed7a00c2b86CC69A")
                .then((bal) => {
                    document.querySelector("#ethPot").innerHTML =
                        ethers.utils.formatEther(bal);
                    document.querySelector("#usdPot").innerHTML = "≈ $" +
                        Math.round(ethPrice * bal * 100) / 100;
                });
            lotto.allTimeWinnings().then((win) => {
                let winne = ethers.utils.formatEther(win);
                document.querySelector("#ethAllTime").innerHTML = "Ξ " + Math.round(winne * 100000) / 100000;
                document.querySelector("#usdAllTime").innerHTML =
                    "$ " + Math.round(ethPrice * winne * 100) / 100;
            });
            provider.getBlockNumber().then((block) => {
                lotto.endingBlock().then((end) => {
                    document.querySelector("#blocksLeft").innerHTML =
                        end - block;
                    document.querySelector("#timeLeft").innerHTML =
                        secondsToHms(Math.abs(end - block) * 13.87);
                });
            });
            setTimeout(startUpdating, 12.57 * 1000);
        });
    }
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

function ethPriceOracle() {
    return new ethers.Contract(
        "0x07D91f5fb9Bf7798734C3f606dB065549F6893bb",
        [
            "function getRateToEth(address srcToken, bool useSrcWrappers) view returns (uint256)",
        ],
        provider
    );
}

function ethPriceChain() {
    return new ethers.Contract(
        "0x64EaC61A2DFda2c3Fa04eED49AA33D021AeC8838",
        ["function latestAnswer() view returns (int256)"],
        provider
    );
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

const buyButton = document.querySelector("#buyButton");

buyButton.addEventListener("click", () => {
    // ethereum.request({ method: "eth_requestAccounts" });
    lotto.buyTickets({ value: document.querySelector("#ticketAmount").value });
});