import { Interface } from "ethers";

export function getSelectors(contract: Interface): string[] {
  let selectors: string[] = [];

  contract.forEachFunction((func) => selectors.push(func.selector));

  return selectors;
}

export enum FacetAction {
  Add,
  Replace,
  Remove,
}
