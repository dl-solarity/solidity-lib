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

        return U512.modadd(call_, a_, b_, m_).toBytes();
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
}
