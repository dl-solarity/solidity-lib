// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract BaseVerifierMock {
    bool public verifyResult;
    uint256[] public expectedInputs;

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

contract Verifier2Mock is BaseVerifierMock {
    constructor(
        bool verifyResult_,
        uint256[] memory expectedInputs_
    ) BaseVerifierMock(verifyResult_, expectedInputs_) {}

    function verifyProof(
        uint256[2] memory,
        uint256[2][2] memory,
        uint256[2] memory,
        uint256[2] memory inputs_
    ) external view returns (bool) {
        for (uint256 i = 0; i < inputs_.length; i++) {
            require(inputs_[i] == expectedInputs[i], "Verifier2Mock: invalid inputs");
        }

        return verifyResult;
    }
}

contract Verifier3Mock is BaseVerifierMock {
    constructor(
        bool verifyResult_,
        uint256[] memory expectedInputs_
    ) BaseVerifierMock(verifyResult_, expectedInputs_) {}

    function verifyProof(
        uint256[2] memory,
        uint256[2][2] memory,
        uint256[2] memory,
        uint256[3] memory inputs_
    ) external view returns (bool) {
        for (uint256 i = 0; i < inputs_.length; i++) {
            require(inputs_[i] == expectedInputs[i], "Verifier3Mock: invalid inputs");
        }

        return verifyResult;
    }
}
