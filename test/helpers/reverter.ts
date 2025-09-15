import { NetworkHelpers, SnapshotRestorer } from "@nomicfoundation/hardhat-network-helpers/types";

export class Reverter {
  private snapshotInstance: SnapshotRestorer | undefined;

  constructor(private networkHelpers: NetworkHelpers) {}

  revert = async () => {
    if (this.snapshotInstance === undefined) {
      throw new Error("this.snapshotInstance is undefined");
    }

    await this.snapshotInstance.restore();
  };

  snapshot = async () => {
    this.snapshotInstance = await this.networkHelpers.takeSnapshot();
  };
}
