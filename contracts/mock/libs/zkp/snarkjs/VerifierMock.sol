// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract BaseVerifierMock {
    bool public verifyResult;

    constructor(bool verifyResult_) {
        verifyResult = verifyResult_;
    }

    function setVerifyResult(bool newResult_) external {
        verifyResult = newResult_;
    }
}

contract Verifier2Mock is BaseVerifierMock {
    constructor(bool verifyResult_) BaseVerifierMock(verifyResult_) {}

    function verifyProof(
        uint256[2] memory,
        uint256[2][2] memory,
        uint256[2] memory,
        uint256[2] memory
    ) external view returns (bool) {
        return verifyResult;
    }
}

contract Verifier3Mock is BaseVerifierMock {
    constructor(bool verifyResult_) BaseVerifierMock(verifyResult_) {}

    function verifyProof(
        uint256[2] memory,
        uint256[2][2] memory,
        uint256[2] memory,
        uint256[3] memory
    ) external view returns (bool) {
        return verifyResult;
    }
}
