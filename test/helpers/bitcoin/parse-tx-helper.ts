import * as fs from "fs";
import path from "path";
import { TransactionData } from "./types";
import { expect } from "chai";

import { TxParser } from "@/generated-types/ethers/contracts/mock/libs/bitcoin/TxParserMock";
import { ZeroHash } from "ethers";
import { addHexPrefix, reverseBytes } from "../bytes-helpers";

export function getTxDataFilePath(fileName: string): string {
  return path.join(__dirname, "../../libs/bitcoin/data", fileName);
}

export function getTxData(pathToDataFile: string, index: number): TransactionData {
  const allTxDataArr = JSON.parse(fs.readFileSync(pathToDataFile, "utf-8")) as TransactionData[];

  return allTxDataArr[index];
}

export function checkTransaction(expectedTx: TxParser.TransactionStructOutput, actualTx: TransactionData) {
  expect(expectedTx.version).to.be.eq(actualTx.version);
  expect(expectedTx.locktime).to.be.eq(actualTx.locktime);

  const hasWitness = actualTx.vsize && actualTx.size && actualTx.vsize < actualTx.size;

  expect(expectedTx.hasWitness).to.be.eq(hasWitness);
  expect(expectedTx.inputs.length).to.be.eq(actualTx.vin.length);

  for (let i = 0; i < actualTx.vin.length; i++) {
    if (!actualTx.vin[i].txid) {
      expect(expectedTx.inputs[i].previousHash).to.be.eq(ZeroHash);
    } else {
      expect(expectedTx.inputs[i].previousHash).to.be.eq(addHexPrefix(actualTx.vin[i].txid));
    }

    if (actualTx.vin[i].vout === undefined) {
      expect(expectedTx.inputs[i].previousIndex).to.be.eq(4294967295);
    } else {
      expect(expectedTx.inputs[i].previousIndex).to.be.eq(actualTx.vin[i].vout);
    }

    expect(expectedTx.inputs[i].sequence).to.be.eq(actualTx.vin[i].sequence);

    if (!actualTx.vin[i].coinbase) {
      expect(expectedTx.inputs[i].script).to.be.eq(addHexPrefix(actualTx.vin[i].scriptSig.hex));
    } else {
      expect(expectedTx.inputs[i].script).to.be.eq(addHexPrefix(actualTx.vin[i].coinbase!));
    }

    if (actualTx.vin[i].txinwitness) {
      expect(expectedTx.inputs[i].witnesses.length).to.be.eq(actualTx.vin[i].txinwitness.length);

      for (let j = 0; j < actualTx.vin[i].txinwitness.length; j++) {
        expect(expectedTx.inputs[i].witnesses[j]).to.be.eq(addHexPrefix(actualTx.vin[i].txinwitness[j]));
      }
    }
  }

  expect(expectedTx.outputs.length).to.be.eq(actualTx.vout.length);

  for (let i = 0; i < actualTx.vout.length; i++) {
    expect(expectedTx.outputs[i].value).to.be.eq(actualTx.vout[i].value * 10 ** 8);
    expect(expectedTx.outputs[i].script).to.be.eq(addHexPrefix(actualTx.vout[i].scriptPubKey.hex));
  }
}

export function parseCuint(data: string, offset: number): [bigint, number] {
  if (data.slice(offset, offset + 2) == "0x") data = data.slice(offset + 2);

  const firstByte = parseInt(data.slice(offset, offset + 2), 16);

  if (firstByte < 0xfd) return [BigInt(reverseBytes(data.slice(offset, offset + 2))), 2];
  if (firstByte == 0xfd) return [BigInt(reverseBytes(data.slice(offset + 2, offset + 6))), 6];
  if (firstByte == 0xfe) return [BigInt(reverseBytes(data.slice(offset + 2, offset + 10))), 10];

  return [BigInt(reverseBytes(data.slice(offset + 2, offset + 18))), 18];
}

export function formatTx(tx: TxParser.TransactionStructOutput) {
  const inputs = [];
  const outputs = [];

  for (let i = 0; i < tx.inputs.length; i++) {
    inputs.push(formatInput(tx, i));
  }

  for (let i = 0; i < tx.outputs.length; i++) {
    outputs.push(formatOutput(tx, i));
  }

  return {
    inputs: inputs,
    outputs: outputs,
    version: tx.version,
    locktime: tx.locktime,
    hasWitness: tx.hasWitness,
  };
}

function formatOutput(tx: TxParser.TransactionStructOutput, index: number) {
  return {
    value: tx.outputs[index].value,
    script: tx.outputs[index].script,
  };
}

function formatInput(tx: TxParser.TransactionStructOutput, index: number) {
  return {
    previousHash: tx.inputs[index].previousHash,
    previousIndex: tx.inputs[index].previousIndex,
    sequence: tx.inputs[index].sequence,
    script: tx.inputs[index].script,
    witnesses: [...tx.inputs[index].witnesses],
  };
}
