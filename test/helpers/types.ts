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

export type TransactionData = {
  txid: string;
  hash: string;
  version: number;
  size: number;
  vsize: number;
  weight: number;
  locktime: number;
  vin: Vin[];
  vout: Vout[];
  hex: string;
  confirmations: number;
  time: number;
  blocktime: number;
};

type Vin = {
  coinbase?: string;
  txid: string;
  vout: number;
  scriptSig: {
    hex: string;
  };
  txinwitness: string[];
  sequence: number;
};

type Vout = {
  value: number;
  n: number;
  scriptPubKey: { hex: string };
};
