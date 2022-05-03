const setNextBlockTime = async (time) => {
  await network.provider.send("evm_setNextBlockTimestamp", [time]);
};

const setTime = async (time) => {
  await network.provider.send("evm_setNextBlockTimestamp", [time]);
  await mine();
};

const getCurrentBlockTime = async () => {
  return (await web3.eth.getBlock(await web3.eth.getBlockNumber())).timestamp;
};

const mine = async (numberOfBlocks = 1) => {
  for (let i = 0; i < numberOfBlocks; i++) {
    await network.provider.send("evm_mine");
  }
};

module.exports = {
  getCurrentBlockTime,
  setNextBlockTime,
  setTime,
  mine,
};
