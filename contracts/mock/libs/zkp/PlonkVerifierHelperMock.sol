// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {PlonkVerifierHelper} from "../../../libs/zkp/PlonkVerifierHelper.sol";

contract PlonkVerifierHelperMock {
    using PlonkVerifierHelper for address;

    function verifyProofPlonkProofStruct(
        address verifier_,
        PlonkVerifierHelper.PlonkProof memory plonkProof_
    ) external view returns (bool) {
        return verifier_.verifyProof(plonkProof_);
    }

    function verifyProofPointsStruct(
        address verifier_,
        PlonkVerifierHelper.ProofPoints memory proofPoints_,
        uint256[] memory pubSignals_
    ) external view returns (bool) {
        return verifier_.verifyProof(proofPoints_, pubSignals_);
    }

    function verifyProof(
        address verifier_,
        uint256[24] memory proofData_,
        uint256[] memory pubSignals_
    ) external view returns (bool) {
        return verifier_.verifyProof(proofData_, pubSignals_);
    }

    function verifyProofPlonkProofStructSafe(
        address verifier_,
        PlonkVerifierHelper.PlonkProof memory plonkProof_,
        uint256 pubSignalsCount_
    ) external view returns (bool) {
        return verifier_.verifyProofSafe(plonkProof_, pubSignalsCount_);
    }

    function verifyProofPointsStructSafe(
        address verifier_,
        PlonkVerifierHelper.ProofPoints memory proofPoints_,
        uint256[] memory pubSignals_,
        uint256 pubSignalsCount_
    ) external view returns (bool) {
        return verifier_.verifyProofSafe(proofPoints_, pubSignals_, pubSignalsCount_);
    }

    function verifyProofSafe(
        address verifier_,
        uint256[24] memory proofData_,
        uint256[] memory pubSignals_,
        uint256 pubSignalsCount_
    ) external view returns (bool) {
        return verifier_.verifyProofSafe(proofData_, pubSignals_, pubSignalsCount_);
    }
}
