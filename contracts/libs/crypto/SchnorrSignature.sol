// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {EC} from "./EC.sol";
import {MemoryUtils} from "../utils/MemoryUtils.sol";

library SchnorrSignature {
    using MemoryUtils for *;

    struct Parameters {
        uint256 a;
        uint256 b;
        uint256 gx;
        uint256 gy;
        uint256 p;
        uint256 n;
    }

    struct _Inputs {
        uint256 rx;
        uint256 ry;
        uint256 e;
        uint256 px;
        uint256 py;
    }

    function verify(
        Parameters memory curveParams_,
        bytes32 hashedMessage_,
        bytes memory signature_,
        bytes memory pubKey_
    ) internal view returns (bool) {
        _Inputs memory inputs_;

        (inputs_.rx, inputs_.ry, inputs_.e) = _parseSignature(signature_);
        (inputs_.px, inputs_.py) = _parsePubKey(pubKey_);

        require(
            EC.isOnCurve(inputs_.rx, inputs_.ry, curveParams_.a, curveParams_.b, curveParams_.p)
        );
        require(
            EC.isOnCurve(inputs_.px, inputs_.py, curveParams_.a, curveParams_.b, curveParams_.p)
        );
        require(EC.isValidScalar(inputs_.e, curveParams_.n));

        EC.Jpoint[16] memory baseShamir_ = EC.preComputeJacobianPoints(
            curveParams_.gx,
            curveParams_.gy,
            curveParams_.p,
            curveParams_.a
        );
        EC.Jpoint memory lhs_ = EC.jMultShamir(
            baseShamir_,
            inputs_.e,
            curveParams_.p,
            curveParams_.a
        );

        uint256 c_ = uint256(
            keccak256(
                abi.encodePacked(
                    curveParams_.gx,
                    curveParams_.gy,
                    inputs_.rx,
                    inputs_.ry,
                    hashedMessage_
                )
            )
        ) % curveParams_.n;

        EC.Jpoint[16] memory pubKeyShamir_ = EC.preComputeJacobianPoints(
            inputs_.px,
            inputs_.py,
            curveParams_.p,
            curveParams_.a
        );
        EC.Jpoint memory rhs_ = EC.jMultShamir(pubKeyShamir_, c_, curveParams_.p, curveParams_.a);
        rhs_ = EC.jAddPoint(
            EC.jacobianFromAffine(inputs_.rx, inputs_.ry),
            rhs_,
            curveParams_.p,
            curveParams_.a
        );

        return EC.jEqual(lhs_, rhs_, curveParams_.p);
    }

    function _parseSignature(
        bytes memory signature_
    ) private pure returns (uint256 rx_, uint256 ry_, uint256 e_) {
        require(signature_.length == 96);

        (rx_, ry_, e_) = abi.decode(signature_, (uint256, uint256, uint256));
    }

    function _parsePubKey(bytes memory pubKey_) private pure returns (uint256 px_, uint256 py_) {
        require(pubKey_.length == 64);

        (px_, py_) = abi.decode(pubKey_, (uint256, uint256));
    }
}
