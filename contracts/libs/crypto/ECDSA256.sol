// SPDX-License-Identifier: MIT
// Reference: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.1.0/contracts/utils/cryptography/P256.sol
pragma solidity ^0.8.21;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {EC256} from "./EC256.sol";

/**
 * @notice Cryptography module
 *
 * This library provides functionality for ECDSA verification over any 256-bit curve.
 *
 * For more information, please refer to the OpenZeppelin documentation.
 */
library ECDSA256 {
    using EC256 for *;

    error LengthIsNot64();

    /**
     * @notice The function to verify the ECDSA signature
     * @param ec the 256-bit curve parameters.
     * @param hashedMessage_ the already hashed message to be verified.
     * @param signature_ the ECDSA signature. Equals to `bytes(r) + bytes(s)`.
     * @param pubKey_ the full public key of a signer. Equals to `bytes(x) + bytes(y)`.
     *
     * Note that signatures only from the lower part of the curve are accepted.
     * If your `s > n / 2`, change it to `s = n - s`.
     */
    function verify(
        EC256.Curve memory ec,
        bytes32 hashedMessage_,
        bytes memory signature_,
        bytes memory pubKey_
    ) internal view returns (bool) {
        unchecked {
            uint256 r_;
            uint256 s_;
            EC256.APoint memory p_;

            (r_, s_) = _split(signature_);
            (p_.x, p_.y) = _split(pubKey_);

            if (!_isProperSignature(ec, r_, s_) || !ec.isOnCurve(p_)) {
                return false;
            }

            uint256 u1_;
            uint256 u2_;

            {
                uint256 w_ = Math.invModPrime(s_, ec.n);
                u1_ = mulmod(uint256(hashedMessage_), w_, ec.n);
                u2_ = mulmod(r_, w_, ec.n);
            }

            EC256.JPoint memory point_ = ec.jMultShamir2(
                p_.toJacobian(),
                ec.jbasepoint(),
                u1_,
                u2_
            );

            return ec.toAffine(point_).x % ec.n == r_;
        }
    }

    /**
     * @dev Checks if (r, s) is a proper signature.
     * In particular, this checks that `s` is in the "lower-range", making the signature non-malleable
     */
    function _isProperSignature(
        EC256.Curve memory ec,
        uint256 r_,
        uint256 s_
    ) private pure returns (bool) {
        return r_ > 0 && r_ < ec.n && s_ > 0 && s_ <= (ec.n >> 1);
    }

    /**
     * @dev Helper function for splitting bytes into two uint256 values. Used for 64-byte signatures and public keys
     */
    function _split(
        bytes memory from2_
    ) private pure returns (uint256 leftPart_, uint256 rightPart_) {
        unchecked {
            if (from2_.length != 64) revert LengthIsNot64();

            assembly ("memory-safe") {
                leftPart_ := mload(add(from2_, 32))
                rightPart_ := mload(add(from2_, 64))
            }

            return (leftPart_, rightPart_);
        }
    }
}
