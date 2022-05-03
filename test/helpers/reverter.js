const ht = require("hardhat");

class Reverter {
  #snapshotId;

  revert() {
    return new Promise((resolve, reject) => {
      ht.network.provider
        .send("evm_revert", [this.#snapshotId])
        .then(() => {
          return resolve(this.snapshot());
        })
        .catch((err) => {
          return reject(err);
        });
    });
  }

  snapshot() {
    return new Promise((resolve, reject) => {
      ht.network.provider
        .send("evm_snapshot", [])
        .then((res) => {
          this.#snapshotId = res;
          return resolve(res);
        })
        .catch((err) => {
          return reject(err);
        });
    });
  }
}

module.exports = Reverter;
