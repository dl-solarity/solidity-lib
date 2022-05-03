const token = artifacts.require("ERC20Mock");

module.exports = async (deployer) => {
  await deployer.deploy(token, "Mock", "Mock", 18);
};
