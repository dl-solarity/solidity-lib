// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {UniswapV3PoolMock} from "./UniswapV3PoolMock.sol";

contract UniswapV3FactoryMock is IUniswapV3Factory {
    address public override owner;

    mapping(uint24 => int24) public override feeAmountTickSpacing;

    mapping(address => mapping(address => mapping(uint24 => address))) public override getPool;

    constructor() {}

    function createPool(
        address tokenA_,
        address tokenB_,
        uint24 fee_
    ) external returns (address pool_) {
        require(tokenA_ != tokenB_);

        (address token0_, address token1_) = tokenA_ < tokenB_ ? (tokenA_, tokenB_) : (tokenB_, tokenA_);

        require(token0_ != address(0));
        require(getPool[token0_][token1_][fee_] == address(0));

        pool_ = deploy(token0_, token1_, fee_);

        getPool[token0_][token1_][fee_] = pool_;
        // populate mapping in the reverse direction, deliberate choice to avoid the cost of comparing addresses
        getPool[token1_][token0_][fee_] = pool_;
    }

    /** @dev Deploys a pool with the given parameters
     * @param token0_ The first token of the pool by address sort order
     * @param token1_ The second token of the pool by address sort order
     * @param fee_ The fee collected upon every swap in the pool, denominated in hundredths of a bip
     */
    function deploy(address token0_, address token1_, uint24 fee_) internal returns (address pool_) {
        pool_ = address(new UniswapV3PoolMock{salt: keccak256(abi.encode(token0_, token1_, fee_))}());
    }

    function enableFeeAmount(uint24 fee_, int24 tickSpacing_) public override {}

    function setOwner(address owner_) external override {}
}
