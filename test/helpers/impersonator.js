const impersonate = async (address) => {
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [address],
  });

  await network.provider.send("hardhat_setBalance", [address, "0xFFFFFFFFFFFFFFFF"]);
};

module.exports = {
  impersonate,
};
