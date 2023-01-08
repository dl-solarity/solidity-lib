const BN = require("bignumber.js");
const { PRECISION } = require("./constants");

const toBN = (value) => new BN(value);

const wei = (value, decimal = 18) => {
  return toBN(value).times(toBN(10).pow(decimal)).toFixed();
};

const fromWei = (value, decimal = 18) => {
  return toBN(value).div(toBN(10).pow(decimal)).toFixed();
};

const precision = (value) => toBN(value).times(PRECISION).toFixed();

const fromPrecision = (value) => toBN(value).div(PRECISION).toFixed();

const accounts = async (index) => {
  return (await web3.eth.getAccounts())[index];
};

module.exports = {
  toBN,
  accounts,
  wei,
  fromWei,
  precision,
  fromPrecision,
};
