// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {Groth16VerifierHelper} from "../../../../libs/zkp/Groth16VerifierHelper.sol";

contract Groth16VerifierHelperMock {
    using Groth16VerifierHelper for address;

    function verifyProofStruct(
        address verifier_,
        Groth16VerifierHelper.ProofPoints memory proofPoints_,
        uint256[] memory pubSignals_
    ) external view returns (bool) {
        return verifier_.verifyProof(proofPoints_, pubSignals_);
    }

    function verifyProof(
        address verifier_,
        uint256[2] memory a_,
        uint256[2][2] memory b_,
        uint256[2] memory c_,
        uint256[] memory pubSignals_
    ) external view returns (bool) {
        return verifier_.verifyProof(a_, b_, c_, pubSignals_);
    }

    function verifyProofStructSafe(
        address verifier_,
        Groth16VerifierHelper.ProofPoints memory proofPoints_,
        uint256[] memory pubSignals_,
        uint256 pubSignalsCount_
    ) external view returns (bool) {
        return verifier_.verifyProofSafe(proofPoints_, pubSignals_, pubSignalsCount_);
    }

    function verifyProofSafe(
        address verifier_,
        uint256[2] memory a_,
        uint256[2][2] memory b_,
        uint256[2] memory c_,
        uint256[] memory pubSignals_,
        uint256 pubSignalsCount_
    ) external view returns (bool) {
        return verifier_.verifyProofSafe(a_, b_, c_, pubSignals_, pubSignalsCount_);
    }
}
