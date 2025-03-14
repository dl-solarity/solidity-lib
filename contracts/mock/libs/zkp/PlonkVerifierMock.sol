// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

contract BasePlonkVerifierMock {
    bool public verifyResult;
    uint256[] public expectedInputs;

    error InvalidInputs();

    constructor(bool verifyResult_, uint256[] memory expectedInputs_) {
        verifyResult = verifyResult_;
        expectedInputs = expectedInputs_;
    }

    function setVerifyResult(bool newResult_) external {
        verifyResult = newResult_;
    }

    function setExpectedInputs(uint256[] memory newExpectedInputs_) external {
        expectedInputs = newExpectedInputs_;
    }
}

contract PlonkVerifier2Mock is BasePlonkVerifierMock {
    constructor(
        bool verifyResult_,
        uint256[] memory expectedInputs_
    ) BasePlonkVerifierMock(verifyResult_, expectedInputs_) {}

    function verifyProof(
        uint256[24] memory,
        uint256[2] memory inputs_
    ) external view returns (bool) {
        for (uint256 i = 0; i < inputs_.length; i++) {
            if (inputs_[i] != expectedInputs[i]) revert InvalidInputs();
        }

        return verifyResult;
    }
}

contract PlonkVerifier3Mock is BasePlonkVerifierMock {
    constructor(
        bool verifyResult_,
        uint256[] memory expectedInputs_
    ) BasePlonkVerifierMock(verifyResult_, expectedInputs_) {}

    function verifyProof(
        uint256[24] memory,
        uint256[3] memory inputs_
    ) external view returns (bool) {
        for (uint256 i = 0; i < inputs_.length; i++) {
            if (inputs_[i] != expectedInputs[i]) revert InvalidInputs();
        }

        return verifyResult;
    }
}
