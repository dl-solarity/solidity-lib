// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract UniswapV2PairMock {
    address public factory;
    address public token0;
    address public token1;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;

    uint112 private _reserve0 = 1; // uses single storage slot, accessible via getReserves
    uint112 private _reserve1 = 2; // uses single storage slot, accessible via getReserves
    uint32 private _blockTimestampLast; // uses single storage slot, accessible via getReserves

    constructor() {
        factory = msg.sender;
    }

    function initialize(address token0_, address token1_) external {
        require(msg.sender == factory, "UniswapV2: FORBIDDEN");

        token0 = token0_;
        token1 = token1_;

        price0CumulativeLast = 5;
        price1CumulativeLast = 1;
    }

    function getReserves()
        public
        view
        returns (uint112 reserve0_, uint112 reserve1_, uint32 blockTimestampLast_)
    {
        reserve0_ = _reserve0;
        reserve1_ = _reserve1;
        blockTimestampLast_ = _blockTimestampLast;
    }

    function setReserves(uint112 reserve0_, uint112 reserve1_) public {
        _reserve0 = reserve0_;
        _reserve1 = reserve1_;
    }

    function setReservesTimestamp(uint32 blockTimestampLast_) public {
        _blockTimestampLast = blockTimestampLast_;
    }

    function setCumulativePrices(uint256 price0_, uint256 price1_) public {
        price0CumulativeLast = price0_;
        price1CumulativeLast = price1_;
    }
}
