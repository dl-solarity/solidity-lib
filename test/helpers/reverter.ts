import { network } from "hardhat";

export class Reverter {
  private snapshotId: any;

  revert = async () => {
    await network.provider.send("evm_revert", [this.snapshotId]);
    await this.snapshot();
  };

  snapshot = async () => {
    this.snapshotId = await network.provider.send("evm_snapshot", []);
  };
}
