const BigNumber = require("bignumber.js");

const toBN = (value) => new BigNumber(value);

const wei = (value, decimal = 18) => {
  return toBN(value).times(toBN(10).pow(decimal)).toFixed();
};

const fromWei = (value, decimal = 18) => {
  return toBN(value).div(toBN(10).pow(decimal)).toFixed();
};

const decimal = (value) => toBN(value).multipliedBy(1e27).toFixed();

const fromDecimal = (value) => toBN(value).dividedBy(1e27).toFixed();

const accounts = async (index) => {
  return (await web3.eth.getAccounts())[index];
};

module.exports = {
  toBN,
  accounts,
  wei,
  fromWei,
  decimal,
  fromDecimal,
};
