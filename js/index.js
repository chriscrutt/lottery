////////////////////////////////////////////////////////////////////////////////
/* non ethereum based functions */
////////////////////////////////////////////////////////////////////////////////

function showPrompt() {
    document.getElementById("prompt").style.display = "block";
}
function buyTickets() {
    // TODO: Implement buying tickets
    document.getElementById("prompt").style.display = "none";
}

function showPrompt() {
    document.getElementById("prompt").style.display = "block";
    document.getElementById("overlay").style.display = "block";
}

document.getElementById("overlay").addEventListener("click", function (event) {
    document.getElementById("prompt").style.display = "none";
    this.style.display = "none";
});

function convert() {
    document.querySelector("#buyToEth").innerHTML =
        "Ξ " +
        ethers.utils.formatEther(document.querySelector("#ticketAmount").value);

    document.querySelector("#buyToUsd").innerHTML =
        "$ " +
        (
            (document.querySelector("#ticketAmount").value * rate) /
            100000000 /
            1000000000000000000
        ).toFixed(2);
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

////////////////////////////////////////////////////////////////////////////////
/* setup ethereum provider/signer/contract getter */
////////////////////////////////////////////////////////////////////////////////

const provider = new ethers.providers.Web3Provider(window.ethereum);
const signer = provider.getSigner();

function getContractInfo(address, abi, write) {
    // This can be an address or an ENS name

    if (!write) {
        // Read-Only
        return new ethers.Contract(address, abi, provider);
    } else {
        // Read-Write
        return new ethers.Contract(address, abi, signer);
    }
}

////////////////////////////////////////////////////////////////////////////////
/* calculate current rate of eth to usd */
////////////////////////////////////////////////////////////////////////////////

var rate;
const priceAddy = "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e";
const priceAbi = ["function latestAnswer() view returns (int256)"];

////////////////////////////////////////////////////////////////////////////////
/* webpage setup */
////////////////////////////////////////////////////////////////////////////////

// when page loads
window.addEventListener("load", function () {
    if (typeof window.ethereum === "undefined") {
        console.log("nooooo");
    } else {
        lotto = getContractInfo(lottoAddy, lottoAbi, true);
        getContractInfo(priceAddy, priceAbi, false)
            .latestAnswer()
            .then((ratee) => {
                rate = ratee;
                startUpdating();
                colorStuff();
                subscribe();
            });
    }
});

function colorStuff() {
    if (typeof window.ethereum !== "undefined") {
        console.log("MetaMask is installed!");
        if (ethereum.selectedAddress != null) {
            if (ethereum.chainId != "0x5") {
                document.querySelector("#connect").style.color = "orangered";
                document.querySelector("#connect").innerHTML = "Switch Network";
            } else {
                document.querySelector("#connect").style.color =
                    "mediumseagreen";
                document.querySelector("#connect").innerHTML = "Connected";
                lotto.isStaking().then((boo) => {
                    if (!boo) {
                        document.querySelector("#stake").style.color =
                            "mediumseagreen";
                        document.querySelector("#stake").style.border =
                            "2px solid mediumseagreen";
                        document.querySelector("#stake").innerHTML =
                            "Enable Staking";
                    }
                });
                lotto.lastWinner().then((win) => {
                    console.log(2);
                    document.querySelector("#lastWinner").innerHTML =
                        "Last Winner: " + win[0];
                    document.querySelector("#lastPot").innerHTML =
                        "Last Pot: " + win[1];
                    document.querySelector("#lastTicket").innerHTML =
                        "Last Winning Ticket: " + win[2];
                });

                // addTimee();

                withdrawRewards();
            }
        }
    }
}

ethereum.on("accountsChanged", function () {
    window.location.reload();
});

ethereum.on("chainChanged", function () {
    window.location.reload();
});

////////////////////////////////////////////////////////////////////////////////
/* webpage update function */
////////////////////////////////////////////////////////////////////////////////

function startUpdating() {
    provider.on("block", (blockNumber) => {
        // if (window.document.hasFocus()) {
        provider.getBalance(lottoAddy).then((bal) => {
            document.querySelector("#ethPot").innerHTML =
                ethers.utils.formatEther(bal);

            lotto.endingBlock().then((end) => {
                let dif = end - blockNumber;
                document.querySelector("#blocksLeft").innerHTML = dif;
                document.querySelector("#timeLeft").innerHTML = secondsToHms(
                    Math.abs(dif) * 12.06
                );
                if (dif <= 0) {
                    document.querySelector("#time").innerHTML = "time passed";
                    if (bal < 1000) {
                        document.querySelector("#add").style.color =
                            "mediumseagreen";
                        document.querySelector("#add").style.border =
                            "2px solid mediumseagreen";
                        document.querySelector("#payout").style.cssText = "";
                    } else {
                        document.querySelector("#payout").style.color =
                            "mediumseagreen";
                        document.querySelector("#payout").style.border =
                            "2px solid mediumseagreen";
                        document.querySelector("#add").style.cssText = "";
                    }
                } else {
                    document.querySelector("#time").innerHTML = "time left";
                }
            });
        });

        lotto.allTimeWinnings().then((allTimeWin) => {
            document.querySelector("#ethAllTime").innerHTML =
                "Ξ " + (allTimeWin / 1000000000000000000).toFixed(4);
        });
        // price.latestAnswer().then((ratee) => {
        //     rate = ratee;
        document.querySelector("#usdPot").innerHTML =
            "≈ $" +
            (
                document.querySelector("#ethPot").innerHTML *
                (rate / 100000000)
            ).toFixed(2);
        document.querySelector("#usdAllTime").innerHTML =
            "$ " +
            (
                parseFloat(
                    document
                        .querySelector("#ethAllTime")
                        .innerHTML.replace(/[^\d.-]/g, "")
                ) *
                (rate / 100000000)
            ).toFixed(2);
        // });
    });
}

////////////////////////////////////////////////////////////////////////////////
/* connect button */
////////////////////////////////////////////////////////////////////////////////

const ethereumButton = document.querySelector("#connect");

ethereumButton.addEventListener("click", () => {
    // ethereum.request({ method: "eth_requestAccounts" });
    provider.send("eth_requestAccounts", []);
    switchChains();
});

// function to switch/add a chain
async function switchChains() {
    try {
        await ethereum.request({
            method: "wallet_switchEthereumChain",
            params: [{ chainId: "0x5" }],
        });
    } catch (switchError) {
        // This error code indicates that the chain has not been added to MetaMask.
        if (switchError.code === 4902) {
            try {
                await ethereum.request({
                    method: "wallet_addEthereumChain",
                    params: [
                        {
                            chainId: "0x5",
                            chainName: "Goerli Test Network",
                            rpcUrls: ["https://goerli.infura.io/v3/"],
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
        params: [{ chainId: "0x5" }],
    });
}

///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
/*
 * last winner
 * last winning ticket
 * last pot
 * after staked update color
 * continuously scan for payout and update last winner
 * make payout and restart yellow when available and green otherwise
 * enable staking yellow if not and say "staking enabled" if is
 * Withdraw fees yellow if available
 * add time yellow if needed
 */
///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/* lotto setup and functions */
////////////////////////////////////////////////////////////////////////////////

var lotto;

const lottoAddy = "0x1F85e6C45B59217073e43E703EA4116f0c4f1320";

const lottoAbi = [
    // Read-Only Functions
    "function accumulatedEth(address account) view returns (uint256)",
    "function allTimeWinnings() view returns (uint256)",
    "function isStaking() view returns (bool)",
    "function endingBlock() view returns (uint256)",
    "function availableEth() view returns (uint256)",
    "function lastWinner() view returns (address, uint256, uint256)",

    // Authenticated Functions
    "function buyTickets() payable",
    "function startStaking()",
    "function payoutAndRestart()",
    "function withdrawFees()",
    "function addTime()",

    // Events
    "event Payout(address account, uint256 winnings, uint256 ticket)",
];

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

const buyButton = document.querySelector("#buyButton");

buyButton.addEventListener("click", () => {
    // ethereum.request({ method: "eth_requestAccounts" });
    lotto.buyTickets({ value: document.querySelector("#ticketAmount").value });
});

const payoutAndRestart = document.querySelector("#payout");

payoutAndRestart.addEventListener("click", () => {
    lotto.payoutAndRestart();
});

const addTime = document.querySelector("#add");

addTime.addEventListener("click", () => {
    lotto.addTime();
});

const startStaking = document.querySelector("#stake");

startStaking.addEventListener("click", () => {
    lotto.startStaking();
});

const withdraw = document.querySelector("#withdraw");

withdraw.addEventListener("click", () => {
    lotto.withdrawFees();
});

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

function subscribe() {
    lotto.on("Payout", (account, winnings, ticket) => {
        window.location.reload();
    });
}

function withdrawRewards() {
    lotto.availableEth().then((available) => {
        if (available > 0) {
            document.querySelector("#earned").innerHTML =
                "Ξ " + ethers.utils.formatEther(available);
            document.querySelector("#withdraw").innerHTML = "Withdraw Rewards";
            document.querySelector("#withdraw").style.color = "mediumseagreen";
            document.querySelector("#withdraw").style.border =
                "2px solid mediumseagreen";
        } else {
            document.querySelector("#withdraw").style.cssText = "";
            document.querySelector("#earned").innerHTML = "";
        }
    });
}
