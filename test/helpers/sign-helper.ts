import { ethers } from "hardhat";
import { TypedDataDomain, TypedDataField } from "ethers";
import { Base7702RecoverableAccount, EIP712 } from "@ethers-v6";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

type CallTuple = [string, bigint, string];

interface BatchExecuteData {
  calls: CallTuple[];
  nonce: bigint;
}

const BatchExecuteTypes: Record<string, TypedDataField[]> = {
  BatchExecute: [
    { name: "callsHash", type: "bytes32" },
    { name: "nonce", type: "uint256" },
  ],
};

async function getDomain(contract: EIP712): Promise<TypedDataDomain> {
  const { fields, name, version, chainId, verifyingContract, salt, extensions } = await contract.eip712Domain();

  if (extensions.length > 0) {
    throw Error("Extensions not implemented");
  }

  const domain: TypedDataDomain = {
    name,
    version,
    chainId,
    verifyingContract,
    salt,
  };

  const domainFieldNames: Array<string> = ["name", "version", "chainId", "verifyingContract", "salt"];

  for (const [i, name] of domainFieldNames.entries()) {
    if (!((fields as any) & (1 << i))) {
      delete (domain as any)[name];
    }
  }

  return domain;
}

export async function getBatchExecuteSignature(
  recoverableAccount: Base7702RecoverableAccount,
  signer: SignerWithAddress,
  data: BatchExecuteData,
): Promise<string> {
  const domain = await getDomain(recoverableAccount as unknown as EIP712);

  const callsData = ethers.AbiCoder.defaultAbiCoder().encode(["tuple(address,uint256,bytes)[]"], [data.calls]);

  return await signer.signTypedData(domain, BatchExecuteTypes, {
    callsHash: ethers.keccak256(callsData),
    nonce: data.nonce,
  });
}
