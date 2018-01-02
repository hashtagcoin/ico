var HDWalletProvider = require("truffle-hdwallet-provider");
var fs = require("fs");

var mnemonic = fs.readFileSync('./mnemonic', 'ascii', function (err,data) {
    if (err) {
        console.log(err);
    }
});

var infuraToken = fs.readFileSync('./infura_token', 'ascii', function (err,data) {
    if (err) {
        console.log(err);
    }
});

module.exports = {
    networks: {
        development: {
            host: "localhost",
            port: 8545,
            network_id: "*", // Match any network id
            gas:4700000,
            gasPrice: 1000000
        },
        ropsten: {
            provider: new HDWalletProvider(mnemonic, "https://ropsten.infura.io/"+infuraToken),
            network_id: 3,
            gas:4700000,
            gasPrice: 1000000
        },
        kovan: {
            provider: new HDWalletProvider(mnemonic, "https://kovan.infura.io/"+infuraToken),
            network_id: 42
        }
    }
};