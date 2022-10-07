const { toBN } = require("./utils");

const ZERO_ADDR = "0x0000000000000000000000000000000000000000";
const ETHER_ADDR = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";

const SECONDS_IN_DAY = 86400;
const SECONDS_IN_MONTH = SECONDS_IN_DAY * 30;

const PRECISION = toBN(10).pow(25);
const PERCENTAGE_100 = PRECISION.times(100);
const DECIMAL = toBN(10).pow(18);

module.exports = {
  ZERO_ADDR,
  ETHER_ADDR,
  SECONDS_IN_DAY,
  SECONDS_IN_MONTH,
  PRECISION,
  PERCENTAGE_100,
  DECIMAL,
};
