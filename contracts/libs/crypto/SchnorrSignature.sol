// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {EC256} from "./EC256.sol";
import {MemoryUtils} from "../utils/MemoryUtils.sol";

library SchnorrSignature {
    using MemoryUtils for *;
    using EC256 for *;

    error LengthIsNot64();
    error LengthIsNot96();
    error InvalidPubKey();
    error InvalidSignature();

    function verify(
        EC256.Curve memory ec,
        bytes32 hashedMessage_,
        bytes memory signature_,
        bytes memory pubKey_
    ) internal view returns (bool) {
        (EC256.Apoint memory r_, uint256 e_) = _parseSignature(signature_);
        EC256.Apoint memory p_ = _parsePubKey(pubKey_);

        if (!ec.isOnCurve(r_) || !ec.isValidScalar(e_)) {
            revert InvalidSignature();
        }

        if (!ec.isOnCurve(p_)) {
            revert InvalidPubKey();
        }

        EC256.Jpoint memory lhs_ = EC256.jMultShamir(ec, ec.basepoint().jacobianFromAffine(), e_);

        uint256 c_ = ec.scalarFromU256(
            uint256(keccak256(abi.encodePacked(ec.gx, ec.gy, r_.x, r_.y, hashedMessage_)))
        );

        EC256.Jpoint memory rhs_ = EC256.jMultShamir(ec, p_.jacobianFromAffine(), c_);
        rhs_ = EC256.jAddPoint(ec, rhs_, r_.jacobianFromAffine());

        return EC256.jEqual(ec, lhs_, rhs_);
    }

    function _parseSignature(
        bytes memory signature_
    ) private pure returns (EC256.Apoint memory r_, uint256 e_) {
        if (signature_.length != 96) {
            revert LengthIsNot96();
        }

        (r_.x, r_.y, e_) = abi.decode(signature_, (uint256, uint256, uint256));
    }

    function _parsePubKey(bytes memory pubKey_) private pure returns (EC256.Apoint memory p_) {
        if (pubKey_.length != 64) {
            revert LengthIsNot64();
        }

        (p_.x, p_.y) = abi.decode(pubKey_, (uint256, uint256));
    }
}
