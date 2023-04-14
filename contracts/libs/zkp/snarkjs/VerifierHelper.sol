// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 *  @notice This library is needed to simplify the interaction with autogenerated contracts
 *  that use [snarkjs](https://www.npmjs.com/package/snarkjs) to verify ZK proofs.
 *
 *  The main problem with these contracts is that the verification function always has the same signature, except for one parameter.
 *  The `input` parameter is a static array `uint256`, the size of which depends on the number of public outputs of ZK proof,
 *  therefore the signatures of the verification functions may be different for different schemes.
 *
 *  With this library there is no need to create many different interfaces for each circuit.
 *  Also, the library functions accept dynamic arrays of public signals, so you don't need to convert them manually to static ones.
 */
library VerifierHelper {
    using Strings for uint256;

    struct ProofPoints {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
    }

    /**
     *  @notice Function to call the `verifyProof` function on the `verifier` contract.
     *  The ZK proof points are wrapped in a structure for convenience
     *  @param verifier_ the address of the autogenerated `Verifier` contract
     *  @param pubSignals_ the array of the ZK proof public signals
     *  @param proofPoints_ the ProofPoints struct with ZK proof points
     *  @return true if the proof is valid, false - otherwise
     */
    function verifyProof(
        address verifier_,
        uint256[] memory pubSignals_,
        ProofPoints memory proofPoints_
    ) internal view returns (bool) {
        return
            _verifyProof(
                verifier_,
                proofPoints_.a,
                proofPoints_.b,
                proofPoints_.c,
                pubSignals_,
                pubSignals_.length
            );
    }

    /**
     *  @notice Function to call the `verifyProof` function on the `verifier` contract
     *  @param verifier_ the address of the autogenerated `Verifier` contract
     *  @param pubSignals_ the array of the ZK proof public signals
     *  @param a_ the A point of the ZK proof
     *  @param b_ the B point of the ZK proof
     *  @param c_ the C point of the ZK proof
     *  @return true if the proof is valid, false - otherwise
     */
    function verifyProof(
        address verifier_,
        uint256[] memory pubSignals_,
        uint256[2] memory a_,
        uint256[2][2] memory b_,
        uint256[2] memory c_
    ) internal view returns (bool) {
        return _verifyProof(verifier_, a_, b_, c_, pubSignals_, pubSignals_.length);
    }

    /**
     *  @notice Function to call the `verifyProof` function on the `verifier` contract.
     *  The ZK proof points are wrapped in a structure for convenience
     *  The length of the `pubSignals_` arr must be strictly equal to `pubSignalsCount_`
     *  @param verifier_ the address of the autogenerated `Verifier` contract
     *  @param pubSignals_ the array of the ZK proof public signals
     *  @param proofPoints_ the ProofPoints struct with ZK proof points
     *  @param pubSignalsCount_ the number of public signals
     *  @return true if the proof is valid, false - otherwise
     */
    function verifyProofSafe(
        address verifier_,
        uint256[] memory pubSignals_,
        ProofPoints memory proofPoints_,
        uint256 pubSignalsCount_
    ) internal view returns (bool) {
        require(
            pubSignals_.length == pubSignalsCount_,
            "VerifierHelper: invalid public signals count"
        );

        return
            _verifyProof(
                verifier_,
                proofPoints_.a,
                proofPoints_.b,
                proofPoints_.c,
                pubSignals_,
                pubSignalsCount_
            );
    }

    /**
     *  @notice Function to call the `verifyProof` function on the `verifier` contract
     *  The length of the `pubSignals_` arr must be strictly equal to `pubSignalsCount_`
     *  @param verifier_ the address of the autogenerated `Verifier` contract
     *  @param pubSignals_ the array of the ZK proof public signals
     *  @param a_ the A point of the ZK proof
     *  @param b_ the B point of the ZK proof
     *  @param c_ the C point of the ZK proof
     *  @param pubSignalsCount_ the number of public signals
     *  @return true if the proof is valid, false - otherwise
     */
    function verifyProofSafe(
        address verifier_,
        uint256[] memory pubSignals_,
        uint256[2] memory a_,
        uint256[2][2] memory b_,
        uint256[2] memory c_,
        uint256 pubSignalsCount_
    ) internal view returns (bool) {
        require(
            pubSignals_.length == pubSignalsCount_,
            "VerifierHelper: invalid public signals count"
        );

        return _verifyProof(verifier_, a_, b_, c_, pubSignals_, pubSignalsCount_);
    }

    function _verifyProof(
        address verifier_,
        uint256[2] memory a_,
        uint256[2][2] memory b_,
        uint256[2] memory c_,
        uint256[] memory pubSignals_,
        uint256 pubSignalsCount_
    ) private view returns (bool) {
        string memory funcSign_ = string(
            abi.encodePacked(
                "verifyProof(uint256[2],uint256[2][2],uint256[2],uint256[",
                pubSignalsCount_.toString(),
                "])"
            )
        );

        // We have to use abi.encodePacked to encode a dynamic array as a static array (without offset and length)
        (bool success_, bytes memory returnData_) = verifier_.staticcall(
            abi.encodePacked(abi.encodeWithSignature(funcSign_, a_, b_, c_), pubSignals_)
        );

        require(success_, "VerifierHelper: failed to call verifyProof function");

        return abi.decode(returnData_, (bool));
    }
}
