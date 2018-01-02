var HotToken = artifacts.require("HorseToken");

module.exports = function(deployer) {
  deployer.deploy(HotToken);
};