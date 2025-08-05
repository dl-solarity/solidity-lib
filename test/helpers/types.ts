import { BigNumberish } from "ethers";

export type HeaderData = {
  height: BigNumberish;
  blockHash: string;
  rawHeader: string;
  parsedBlockHeader: ParsedBlockHeaderData;
};

export type ParsedBlockHeaderData = {
  hash: string;
  confirmations: BigNumberish;
  height: BigNumberish;
  version: BigNumberish;
  versionHex: BigNumberish;
  merkleroot: string;
  time: BigNumberish;
  mediantime: BigNumberish;
  nonce: BigNumberish;
  bits: string;
  difficulty: BigNumberish;
  chainwork: string;
  nTx: BigNumberish;
  previousblockhash: string;
  nextblockhash: string;
};
