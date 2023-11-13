// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//codestyle

import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {UniswapV3PoolMock} from "./UniswapV3PoolMock.sol";

contract UniswapV3FactoryMock is IUniswapV3Factory {
    address public override owner;

    mapping(uint24 => int24) public override feeAmountTickSpacing;

    mapping(address => mapping(address => mapping(uint24 => address))) public override getPool;

    constructor() {}

    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool) {
        require(tokenA != tokenB);

        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        require(token0 != address(0));
        require(getPool[token0][token1][fee] == address(0));

        pool = deploy(token0, token1, fee);

        getPool[token0][token1][fee] = pool;
        // populate mapping in the reverse direction, deliberate choice to avoid the cost of comparing addresses
        getPool[token1][token0][fee] = pool;
    }

    /** @dev Deploys a pool with the given parameters
     * @param token0 The first token of the pool by address sort order
     * @param token1 The second token of the pool by address sort order
     * @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
     */
    function deploy(address token0, address token1, uint24 fee) internal returns (address pool) {
        pool = address(new UniswapV3PoolMock{salt: keccak256(abi.encode(token0, token1, fee))}());
    }

    function setOwner(address _owner) external override {}

    function enableFeeAmount(uint24 fee, int24 tickSpacing) public override {}
}
