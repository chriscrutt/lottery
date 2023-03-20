const Implementation = artifacts.require("Implementation");

module.exports = function (deployer) {
    deployer.deploy(Implementation, "Token Name", "TKN", ["0x92DF544228Ca92b8C9943BBeECFDA7D3377f6294"]);
};
