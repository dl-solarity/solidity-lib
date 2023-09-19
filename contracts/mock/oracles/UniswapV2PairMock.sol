// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract UniswapV2PairMock {
    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0 = 1; // uses single storage slot, accessible via getReserves
    uint112 private reserve1 = 2; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;

    function getReserves()
        public
        view
        returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast)
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function setReserves(uint112 reserve0_, uint112 reserve1_) public {
        reserve0 = reserve0_;
        reserve1 = reserve1_;
    }

    function setReservesTimestamp(uint32 blockTimestampLast_) public {
        blockTimestampLast = blockTimestampLast_;
    }

    function setCumulativePrices(uint256 price0_, uint256 price1_) public {
        price0CumulativeLast = price0_;
        price1CumulativeLast = price1_;
    }

    constructor() {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "UniswapV2: FORBIDDEN"); // sufficient check
        token0 = _token0;
        token1 = _token1;

        price0CumulativeLast = 5;
        price1CumulativeLast = 1;
    }
}
