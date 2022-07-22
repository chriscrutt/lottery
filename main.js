window.addEventListener("load", function () {
    if (typeof window.ethereum === "undefined") {
        document.querySelector("#connect").innerHTML = "Requires MetaMask";
        document.querySelector("#connect").style.background = "yellow";
        document.querySelector("#mask").style.display = "block";
        console.log("nooooo");
    } else {
        colorStuff();
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
    colorStuff();
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

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

const etherBalanceButton = document.querySelector("#etherBalanceButton");

etherBalanceButton.addEventListener("click", async () => {
    balance = await provider.getBalance(signer.getAddress());
    document.querySelector("#etherBalance").innerHTML =
        ethers.utils.commify(ethers.utils.formatEther(balance)) + " Ether";
    document.querySelector("#etherBalance").style.display = "block";
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

const sendEthButton = document.querySelector("#sendEthButton");

//Sending Ethereum to an address
sendEthButton.addEventListener("click", async () => {
    const tx = signer
        .sendTransaction({
            to: await provider.resolveName(document.querySelector("#to").value),
            value: ethers.utils.parseEther(
                document.querySelector("#ether").value
            ),
            data: hexify(document.querySelector("#message").value),
        })
        .then((txHash) => {
            document.querySelector("#sendEth").innerHTML = txHash.hash;
            document.querySelector("#sendEth").style.display = "block";
            document.querySelector("#sendEth").href = "https://kovan.etherscan.io/tx/" + txHash.hash;
        })
        .catch((error) => console.error);
});

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

function dropIt() {
    document.getElementById("myDropdown").classList.toggle("show");
}

// Close the dropdown if the user clicks outside of it
window.onclick = function (event) {
    if (!event.target.matches("#dropbtn")) {
        var dropdowns = document.getElementsByClassName("dropdown-content");
        var i;
        for (i = 0; i < dropdowns.length; i++) {
            var openDropdown = dropdowns[i];
            if (openDropdown.classList.contains("show")) {
                openDropdown.classList.remove("show");
            }
        }
    }
};

const options = document.querySelector(".options");

function doSomething(a) {
    document.querySelector("#dropbtn").innerHTML = a.innerText;
}

let tokens = {
    BAL: "0x41286Bb1D3E870f3F750eB7E1C25d7E48c8A1Ac7",
    DAI: "0x04DF6e4121c27713ED22341E7c7Df330F56f289B",
    GUSD: "0x22ee6c3B011fACC530dd01fe94C58919344d6Db5",
};

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

// A Human-Readable ABI; for interacting with the contract, we
// must include any fragment we wish to use
const abi = [
    // Read-Only Functions
    "function balanceOf(address owner) view returns (uint256)",
    "function decimals() view returns (uint8)",
    "function symbol() view returns (string)",

    // Authenticated Functions
    "function transfer(address to, uint amount) returns (bool)",

    // Events
    "event Transfer(address indexed from, address indexed to, uint amount)",
];

function getTokenInfo(write) {
    try {
        // This can be an address or an ENS name
        let address = tokens[document.querySelector("#dropbtn").innerHTML];

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
    } catch (err) {
        document.getElementById("dropbtn").innerHTML = "select a coin";
        document.getElementById("dropbtn").style.color = "red";
        console.error;
    }
}

const tokenBalanceButton = document.querySelector("#tokenBalanceButton");

tokenBalanceButton.addEventListener("click", async () => {
    const erc20 = getTokenInfo(false);
    const num = erc20
        .balanceOf(signer.getAddress())
        .then(async (p) => {
            yo = await p;
            document.querySelector("#tokenBalance").innerHTML =
                ethers.utils.commify(
                    ethers.utils.formatUnits(p._hex, await erc20.decimals())
                ) +
                " " +
                document.querySelector("#dropbtn").innerHTML;
            document.querySelector("#tokenBalance").style.display = "block";
            document.getElementById("dropbtn").style.color = "white";
        })
        .catch((error) => console.error);
});

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

const sendTokenButton = document.querySelector("#sendTokenButton");

//Sending Dai to an address
sendTokenButton.addEventListener("click", async () => {
    const erc20_rw = getTokenInfo(true);
    const tx = await erc20_rw
        .transfer(
            await provider.resolveName(
                document.querySelector("#toToken").value
            ),
            ethers.utils.parseUnits(
                document.querySelector("#token").value,
                await erc20_rw.decimals()
            )
        )
        .then((txHash) => {
            document.querySelector("#sendToken").innerHTML = txHash.hash;
            document.querySelector("#sendToken").style.display = "block";
            document.querySelector("#sendToken").href = "https://kovan.etherscan.io/tx/" + txHash.hash;
        })
        .catch((error) => console.error);
});
