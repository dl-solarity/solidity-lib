const ht = require("hardhat");

class Reverter {
  #snapshotId;

  revert = async () => {
    await ht.network.provider.send("evm_revert", [this.#snapshotId]);
    await this.snapshot();
  };

  snapshot = async () => {
    this.#snapshotId = await ht.network.provider.send("evm_snapshot", []);
  };
}

module.exports = Reverter;
