const setNextBlockTime = async (time) => {
  await network.provider.send("evm_setNextBlockTimestamp", [time]);
};

const setTime = async (time) => {
  await setNextBlockTime(time);
  await mine();
};

const getCurrentBlock = async () => {
  return await web3.eth.getBlockNumber();
};

const getCurrentBlockTime = async () => {
  return (await web3.eth.getBlock(await getCurrentBlock())).timestamp;
};

const mine = async (numberOfBlocks = 1) => {
  for (let i = 0; i < numberOfBlocks; i++) {
    await network.provider.send("evm_mine");
  }
};

module.exports = {
  getCurrentBlock,
  getCurrentBlockTime,
  setNextBlockTime,
  setTime,
  mine,
};
