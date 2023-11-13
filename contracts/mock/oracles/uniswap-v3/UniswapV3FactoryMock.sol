// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
//codestyle

import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {UniswapV3PoolDeployerMock} from "./UniswapV3PoolDeployerMock.sol";
//import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

contract UniswapV3FactoryMock is IUniswapV3Factory, UniswapV3PoolDeployerMock {
    address public override owner;

    mapping(uint24 => int24) public override feeAmountTickSpacing;

    mapping(address => mapping(address => mapping(uint24 => address))) public override getPool;

    constructor() {
        owner = msg.sender;

        feeAmountTickSpacing[500] = 10;
       // emit FeeAmountEnabled(500, 10);
        feeAmountTickSpacing[3000] = 60;
       // emit FeeAmountEnabled(3000, 60);
        feeAmountTickSpacing[10000] = 200;
       // emit FeeAmountEnabled(10000, 200);
    }

    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool) {
        require(tokenA != tokenB);
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0));
        int24 tickSpacing = feeAmountTickSpacing[fee];
        require(tickSpacing != 0);
        require(getPool[token0][token1][fee] == address(0));
        pool = deploy(address(this), token0, token1, fee, tickSpacing);
        getPool[token0][token1][fee] = pool;
        // populate mapping in the reverse direction, deliberate choice to avoid the cost of comparing addresses
        getPool[token1][token0][fee] = pool;
        //emit PoolCreated(token0, token1, fee, tickSpacing, pool);
    }

    function setOwner(address _owner) external override {}

    function enableFeeAmount(uint24 fee, int24 tickSpacing) public override {}
}
