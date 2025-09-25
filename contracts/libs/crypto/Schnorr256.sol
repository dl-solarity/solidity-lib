// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {EC256} from "./EC256.sol";
import {MemoryUtils} from "../utils/MemoryUtils.sol";

/**
 * @notice Cryptography module
 *
 * This library provides functionality for Schnorr signature verification over any 256-bit curve,
 * together with secret extraction from a standard/adaptor Schnorr signature pair.
 */
library Schnorr256 {
    using MemoryUtils for *;
    using EC256 for *;

    error LengthIsNot64();
    error LengthIsNot96();
    error InvalidSignature();
    error InvalidAdaptorSignature();

    /**
     * @notice The function to verify the Schnorr signature
     * @param ec the 256-bit curve parameters.
     * @param hashedMessage_ the already hashed message to be verified.
     * @param signature_ the Schnorr signature. Equals to `bytes(R) + bytes(e)`.
     * @param pubKey_ the full public key of a signer. Equals to `bytes(x) + bytes(y)`.
     * @return True if the signature is valid, false otherwise.
     */
    function verify(
        EC256.Curve memory ec,
        bytes32 hashedMessage_,
        bytes memory signature_,
        bytes memory pubKey_
    ) internal view returns (bool) {
        (EC256.APoint memory r_, uint256 e_) = _parseSignature(signature_);

        return _verify(ec, hashedMessage_, pubKey_, e_, r_, r_);
    }

    /**
     * @notice The function to extract the adaptor secret from a pair of Schnorr signatures.
     * @dev Reverts if the standard or adaptor Schnorr signature is invalid.
     *
     *      The adaptor Schnorr signature is expected to be computed as:
     *          c = H(P || (R + T) || m)
     *          e' = (r + c * privKey) mod n
     *          signature = (R, e')
     *
     *      The standard Schnorr signature is expected to be computed from the adaptor one as:
     *          e = e' + t = (r + t + c * privKey) mod n
     *          signature = (R + T, e)
     *
     *      Secret extraction is performed as follows:
     *          t = (e - e') mod n
     *
     * @param ec the 256-bit curve parameters.
     * @param hashedMessage_ the already hashed message signed.
     * @param signature_ the Schnorr signature. Equals to `bytes(R + T) + bytes(e)`.
     * @param adaptorSignature_ the adaptor Schnorr signature. Equals to `bytes(R) + bytes(e')`.
     * @param pubKey_ the full public key of a signer. Equals to `bytes(x) + bytes(y)`.
     * @return secret_ the secret scalar that was used in the adaptor signature.
     */
    function extract(
        EC256.Curve memory ec,
        bytes32 hashedMessage_,
        bytes memory signature_,
        bytes memory adaptorSignature_,
        bytes memory pubKey_
    ) internal view returns (uint256 secret_) {
        (EC256.APoint memory nonce_, uint256 sigScalar_) = _parseSignature(signature_);
        (EC256.APoint memory adaptorNonce_, uint256 adaptorScalar_) = _parseSignature(
            adaptorSignature_
        );

        secret_ = addmod(sigScalar_, ec.n - adaptorScalar_, ec.n);

        if (!_verify(ec, hashedMessage_, pubKey_, sigScalar_, nonce_, nonce_)) {
            revert InvalidSignature();
        }

        EC256.APoint memory secretPoint_ = ec.toAffine(ec.jMultShamir(ec.jbasepoint(), secret_));

        EC256.APoint memory rt_ = ec.toAffine(
            ec.jAddPoint(adaptorNonce_.toJacobian(), secretPoint_.toJacobian())
        );

        if (!_verify(ec, hashedMessage_, pubKey_, adaptorScalar_, adaptorNonce_, rt_)) {
            revert InvalidAdaptorSignature();
        }
    }

    function _verify(
        EC256.Curve memory ec,
        bytes32 hashedMessage_,
        bytes memory pubKey_,
        uint256 e_,
        EC256.APoint memory r_,
        EC256.APoint memory RT_
    ) private view returns (bool) {
        EC256.APoint memory p_ = _parsePubKey(pubKey_);

        if (!ec.isOnCurve(r_) || !ec.isOnCurve(p_) || !ec.isValidScalar(e_)) {
            return false;
        }

        EC256.JPoint memory lhs_ = ec.jMultShamir(ec.jbasepoint(), e_);

        uint256 c_ = ec.toScalar(
            uint256(keccak256(abi.encodePacked(p_.x, p_.y, RT_.x, RT_.y, hashedMessage_)))
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
