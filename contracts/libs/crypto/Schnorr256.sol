// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {EC256} from "./EC256.sol";
import {MemoryUtils} from "../utils/MemoryUtils.sol";

/**
 * @notice Cryptography module
 *
 * This library provides functionality for Schnorr signature verification over any 256-bit curve.
 */
library Schnorr256 {
    using MemoryUtils for *;
    using EC256 for *;

    error LengthIsNot64();
    error LengthIsNot96();

    /**
     * @notice The function to verify the Schnorr signature
     * @param ec the 256-bit curve parameters.
     * @param hashedMessage_ the already hashed message to be verified.
     * @param signature_ the Schnorr signature. Equals to `bytes(R) + bytes(e)`.
     * @param pubKey_ the full public key of a signer. Equals to `bytes(x) + bytes(y)`.
     */
    function verify(
        EC256.Curve memory ec,
        bytes32 hashedMessage_,
        bytes memory signature_,
        bytes memory pubKey_
    ) internal view returns (bool) {
        (EC256.APoint memory r_, uint256 e_) = _parseSignature(signature_);
        EC256.APoint memory p_ = _parsePubKey(pubKey_);

        if (!ec.isOnCurve(r_) || !ec.isOnCurve(p_) || !ec.isValidScalar(e_)) {
            return false;
        }

        EC256.JPoint memory lhs_ = ec.jMultShamir(ec.jbasepoint(), e_);

        uint256 c_ = ec.toScalar(
            uint256(keccak256(abi.encodePacked(ec.gx, ec.gy, r_.x, r_.y, hashedMessage_)))
        );

        EC256.JPoint memory rhs_ = ec.jMultShamir(p_.toJacobian(), c_);
        rhs_ = ec.jAddPoint(rhs_, r_.toJacobian());

        return ec.jEqual(lhs_, rhs_);
    }

    /**
     * @dev Helper function for splitting 96-byte signature into R (affine point) and e (scalar) components.
     */
    function _parseSignature(
        bytes memory signature_
    ) private pure returns (EC256.APoint memory r_, uint256 e_) {
        if (signature_.length != 96) {
            revert LengthIsNot96();
        }

        (r_.x, r_.y, e_) = abi.decode(signature_, (uint256, uint256, uint256));
    }

    /**
     * @dev Helper function for converting 64-byte pub key into affine point.
     */
    function _parsePubKey(bytes memory pubKey_) private pure returns (EC256.APoint memory p_) {
        if (pubKey_.length != 64) {
            revert LengthIsNot64();
        }

        (p_.x, p_.y) = abi.decode(pubKey_, (uint256, uint256));
    }
}
