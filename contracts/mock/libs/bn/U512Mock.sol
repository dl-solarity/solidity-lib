// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {call} from "../../../libs/bn/U512.sol";
import {uint512} from "../../../libs/bn/U512.sol";
import {U512} from "../../../libs/bn/U512.sol";

contract U512Mock {
    using U512 for *;

    function copy(
        uint256 u256_
    )
        external
        pure
        returns (
            uint512 pointerOriginal_,
            uint512 pointerCopy_,
            bytes memory valueOriginal_,
            bytes memory valueCopy_
        )
    {
        pointerOriginal_ = U512.fromUint256(u256_);
        valueOriginal_ = U512.toBytes(pointerOriginal_);

        pointerCopy_ = U512.copy(pointerOriginal_);
        valueCopy_ = U512.toBytes(pointerCopy_);
    }

    function isNull(uint512 pointer_) external pure returns (bool isNull_) {
        return U512.isNull(pointer_);
    }

    function eq(bytes memory aBytes_, bytes memory bBytes_) external view returns (bool eq_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);

        return U512.eq(a_, b_);
    }

    function eqOperator(
        bytes memory aBytes_,
        bytes memory bBytes_
    ) external view returns (bool eq_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);

        return a_ == b_;
    }

    function eqUint256(bytes memory aBytes_, uint256 u256_) external view returns (bool eq_) {
        uint512 a_ = U512.fromBytes(aBytes_);

        return U512.eqUint256(a_, u256_);
    }

    function cmp(bytes memory aBytes_, bytes memory bBytes_) external view returns (int256) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);

        return U512.cmp(a_, b_);
    }

    function mod(
        bytes memory aBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        return U512.mod(call_, a_, m_).toBytes();
    }

    function modAssign(
        bytes memory aBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        U512.modAssign(call_, a_, m_);

        return a_.toBytes();
    }

    function modAssignTo(
        bytes memory aBytes_,
        bytes memory mBytes_,
        bytes memory toBytes_
    ) external view returns (bytes memory rBytes_) {
        call call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);
        uint512 to_ = U512.fromBytes(toBytes_);

        U512.modAssignTo(call_, a_, m_, to_);

        return to_.toBytes();
    }

    function modinv(
        bytes memory aBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        return U512.modinv(call_, a_, m_).toBytes();
    }

    function modinvAssign(
        bytes memory aBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        U512.modinvAssign(call_, a_, m_);

        return a_.toBytes();
    }

    function modinvAssignTo(
        bytes memory aBytes_,
        bytes memory mBytes_,
        bytes memory toBytes_
    ) external view returns (bytes memory rBytes_) {
        call call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);
        uint512 to_ = U512.fromBytes(toBytes_);

        U512.modinvAssignTo(call_, a_, m_, to_);

        return to_.toBytes();
    }

    function add(
        bytes memory aBytes_,
        bytes memory bBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);

        return U512.add(a_, b_).toBytes();
    }

    function addOperator(
        bytes memory aBytes_,
        bytes memory bBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);

        return (a_ + b_).toBytes();
    }

    function addAssign(
        bytes memory aBytes_,
        bytes memory bBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);

        U512.addAssign(a_, b_);

        return a_.toBytes();
    }

    function addAssignTo(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory toBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 to_ = U512.fromBytes(toBytes_);

        U512.addAssignTo(a_, b_, to_);

        return to_.toBytes();
    }

    function sub(
        bytes memory aBytes_,
        bytes memory bBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);

        return U512.sub(a_, b_).toBytes();
    }

    function subOperator(
        bytes memory aBytes_,
        bytes memory bBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);

        return (a_ - b_).toBytes();
    }

    function subAssign(
        bytes memory aBytes_,
        bytes memory bBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);

        U512.subAssign(a_, b_);

        return a_.toBytes();
    }

    function subAssignTo(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory toBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 to_ = U512.fromBytes(toBytes_);

        U512.subAssignTo(a_, b_, to_);

        return to_.toBytes();
    }

    function mul(
        bytes memory aBytes_,
        bytes memory bBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);

        return U512.mul(a_, b_).toBytes();
    }

    function mulOperator(
        bytes memory aBytes_,
        bytes memory bBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);

        return (a_ * b_).toBytes();
    }

    function mulAssign(
        bytes memory aBytes_,
        bytes memory bBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);

        U512.mulAssign(a_, b_);

        return a_.toBytes();
    }

    function mulAssignTo(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory toBytes_
    ) external view returns (bytes memory rBytes_) {
        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 to_ = U512.fromBytes(toBytes_);

        U512.mulAssignTo(a_, b_, to_);

        return to_.toBytes();
    }

    function modadd(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        return U512.modadd(call_, a_, b_, m_).toBytes();
    }

    function modaddAssign(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        U512.modaddAssign(call_, a_, b_, m_);

        return a_.toBytes();
    }

    function modaddAssignTo(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_,
        bytes memory toBytes_
    ) external view returns (bytes memory rBytes_) {
        call call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);
        uint512 to_ = U512.fromBytes(toBytes_);

        U512.modaddAssignTo(call_, a_, b_, m_, to_);

        return to_.toBytes();
    }

    function redadd(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        return U512.redadd(call_, a_, b_, m_).toBytes();
    }

    function redaddAssign(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        U512.redaddAssign(call_, a_, b_, m_);

        return a_.toBytes();
    }

    function redaddAssignTo(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_,
        bytes memory toBytes_
    ) external view returns (bytes memory rBytes_) {
        call call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);
        uint512 to_ = U512.fromBytes(toBytes_);

        U512.redaddAssignTo(call_, a_, b_, m_, to_);

        return to_.toBytes();
    }

    function modsub(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        return U512.modsub(call_, a_, b_, m_).toBytes();
    }

    function modsubAssign(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        U512.modsubAssign(call_, a_, b_, m_);

        return a_.toBytes();
    }

    function modsubAssignTo(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_,
        bytes memory toBytes_
    ) external view returns (bytes memory rBytes_) {
        call call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);
        uint512 to_ = U512.fromBytes(toBytes_);

        U512.modsubAssignTo(call_, a_, b_, m_, to_);

        return to_.toBytes();
    }

    function redsub(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        return U512.redsub(call_, a_, b_, m_).toBytes();
    }

    function redsubAssign(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        U512.redsubAssign(call_, a_, b_, m_);

        return a_.toBytes();
    }

    function redsubAssignTo(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_,
        bytes memory toBytes_
    ) external view returns (bytes memory rBytes_) {
        call call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);
        uint512 to_ = U512.fromBytes(toBytes_);

        U512.redsubAssignTo(call_, a_, b_, m_, to_);

        return to_.toBytes();
    }

    function modmul(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        return U512.modmul(call_, a_, b_, m_).toBytes();
    }

    function modmulAssign(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        U512.modmulAssign(call_, a_, b_, m_);

        return a_.toBytes();
    }

    function modmulAssignTo(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_,
        bytes memory toBytes_
    ) external view returns (bytes memory rBytes_) {
        call call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);
        uint512 to_ = U512.fromBytes(toBytes_);

        U512.modmulAssignTo(call_, a_, b_, m_, to_);

        return to_.toBytes();
    }

    function modexp(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        return U512.modexp(call_, a_, b_, m_).toBytes();
    }

    function modexpAssign(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        U512.modexpAssign(call_, a_, b_, m_);

        return a_.toBytes();
    }

    function modexpAssignTo(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_,
        bytes memory toBytes_
    ) external view returns (bytes memory rBytes_) {
        call call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);
        uint512 to_ = U512.fromBytes(toBytes_);

        U512.modexpAssignTo(call_, a_, b_, m_, to_);

        return to_.toBytes();
    }

    function moddiv(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        return U512.moddiv(call_, a_, b_, m_).toBytes();
    }

    function moddivAssign(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        U512.moddivAssign(call_, a_, b_, m_);

        return a_.toBytes();
    }

    function moddivAssignTo(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_,
        bytes memory toBytes_
    ) external view returns (bytes memory rBytes_) {
        call call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);
        uint512 to_ = U512.fromBytes(toBytes_);

        U512.moddivAssignTo(call_, a_, b_, m_, to_);

        return to_.toBytes();
    }
}
