// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {call} from "../../../../libs/crypto/bn/U512.sol";
import {uint512} from "../../../../libs/crypto/bn/U512.sol";
import {U512} from "../../../../libs/crypto/bn/U512.sol";

contract U512Mock {
    using U512 for *;

    function modadd(
        bytes memory aBytes_,
        bytes memory bBytes_,
        bytes memory mBytes_
    ) external view returns (bytes memory rBytes_) {
        call call_ = U512.initCall();

        uint512 a_ = U512.fromBytes(aBytes_);
        uint512 b_ = U512.fromBytes(bBytes_);
        uint512 m_ = U512.fromBytes(mBytes_);

        return modaddGas(call_, a_, b_, m_).toBytes();
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

        return modsubGas(call_, a_, b_, m_).toBytes();
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

        return modmulGas(call_, a_, b_, m_).toBytes();
    }

    function modaddGas(
        call call_,
        uint512 a_,
        uint512 b_,
        uint512 m_
    ) public view returns (uint512) {
        return U512.modadd(call_, a_, b_, m_);
    }

    function modsubGas(
        call call_,
        uint512 a_,
        uint512 b_,
        uint512 m_
    ) public view returns (uint512) {
        return U512.modsub(call_, a_, b_, m_);
    }

    function modmulGas(
        call call_,
        uint512 a_,
        uint512 b_,
        uint512 m_
    ) public view returns (uint512) {
        return U512.modmul(call_, a_, b_, m_);
    }
}
