import * as fs from "fs";
import path from "path";
import { expect } from "chai";

import { addHexPrefix, reverseBytes, reverseUint32 } from "../bytes-helpers";
import { BlockHeader } from "@/generated-types/ethers/contracts/mock/libs/bitcoin/BlockHeaderMock";
import { HeaderData } from "./types";

export function getBlocksDataFilePath(fileName: string): string {
  return path.join(__dirname, "../../libs/bitcoin/data", fileName);
}

export function getBlockHeaderData(pathToDataFile: string, height: number): HeaderData {
  const allBlocksDataArr = JSON.parse(fs.readFileSync(pathToDataFile, "utf-8")) as HeaderData[];
  const firstElementHeight = allBlocksDataArr[0].height;

  return formatBlockHeaderData(allBlocksDataArr[height - Number(firstElementHeight)]);
}

export function checkBlockHeaderDataInBE(
  actualBlockHeaderData: BlockHeader.HeaderDataStruct,
  expectedBlockHeaderData: HeaderData,
) {
  expect(actualBlockHeaderData.version).to.be.eq(expectedBlockHeaderData.parsedBlockHeader.version);
  expect(actualBlockHeaderData.bits).to.be.eq(expectedBlockHeaderData.parsedBlockHeader.bits);
  expect(actualBlockHeaderData.prevBlockHash).to.be.eq(expectedBlockHeaderData.parsedBlockHeader.previousblockhash);
  expect(actualBlockHeaderData.merkleRoot).to.be.eq(expectedBlockHeaderData.parsedBlockHeader.merkleroot);
  expect(actualBlockHeaderData.nonce).to.be.eq(expectedBlockHeaderData.parsedBlockHeader.nonce);
  expect(actualBlockHeaderData.time).to.be.eq(expectedBlockHeaderData.parsedBlockHeader.time);
}

export function checkBlockHeaderDataInLE(
  actualBlockHeaderData: BlockHeader.HeaderDataStruct,
  expectedBlockHeaderData: HeaderData,
) {
  expect(actualBlockHeaderData.version).to.be.eq(reverseUint32(expectedBlockHeaderData.parsedBlockHeader.version));
  expect(actualBlockHeaderData.bits).to.be.eq(reverseBytes(expectedBlockHeaderData.parsedBlockHeader.bits));
  expect(actualBlockHeaderData.prevBlockHash).to.be.eq(
    reverseBytes(expectedBlockHeaderData.parsedBlockHeader.previousblockhash),
  );
  expect(actualBlockHeaderData.merkleRoot).to.be.eq(reverseBytes(expectedBlockHeaderData.parsedBlockHeader.merkleroot));
  expect(actualBlockHeaderData.nonce).to.be.eq(reverseUint32(expectedBlockHeaderData.parsedBlockHeader.nonce));
  expect(actualBlockHeaderData.time).to.be.eq(reverseUint32(expectedBlockHeaderData.parsedBlockHeader.time));
}

function formatBlockHeaderData(headerData: HeaderData): HeaderData {
  headerData.blockHash = addHexPrefix(headerData.blockHash);
  headerData.rawHeader = addHexPrefix(headerData.rawHeader);
  headerData.parsedBlockHeader.hash = addHexPrefix(headerData.parsedBlockHeader.hash);
  headerData.parsedBlockHeader.previousblockhash = addHexPrefix(headerData.parsedBlockHeader.previousblockhash);
  headerData.parsedBlockHeader.nextblockhash = addHexPrefix(headerData.parsedBlockHeader.previousblockhash);
  headerData.parsedBlockHeader.merkleroot = addHexPrefix(headerData.parsedBlockHeader.merkleroot);
  headerData.parsedBlockHeader.bits = addHexPrefix(headerData.parsedBlockHeader.bits);
  headerData.parsedBlockHeader.chainwork = addHexPrefix(headerData.parsedBlockHeader.chainwork);

  return headerData;
}
