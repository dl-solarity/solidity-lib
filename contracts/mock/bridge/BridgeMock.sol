// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {ABridge} from "../../bridge/ABridge.sol";
import {IBatcher} from "../../interfaces/bridge/IBatcher.sol";

contract BridgeMock is ABridge {
    event BatchExecuted(address sender, uint256 id);

    function __BridgeMock_init(
        string memory network_,
        uint256[] memory assetTypes_,
        address[] memory handlers_,
        address[] calldata signers_,
        uint256 signaturesThreshold_
    ) external initializer {
        __ABridge_init(network_, assetTypes_, handlers_, signers_, signaturesThreshold_);
    }

    function mockInit() external {
        __ABridge_init("", new uint256[](0), new address[](0), new address[](0), 0);
    }

    function setBatcher(address batcher_) external {
        _setBatcher(IBatcher(batcher_));
    }

    function emitBatchEvent(uint256 id_) external {
        emit BatchExecuted(msg.sender, id_);
    }

    function setSignaturesThreshold(uint256 signaturesThreshold_) external {
        _setSignaturesThreshold(signaturesThreshold_);
    }

    function addSigners(address[] calldata signers_) external {
        _addSigners(signers_);
    }

    function removeSigners(address[] calldata signers_) external {
        _removeSigners(signers_);
    }

    function addHandler(uint256 assetType_, address handler_) external {
        _addHandler(assetType_, handler_);
    }

    function removeHandler(uint256 assetType_) external {
        _removeHandler(assetType_);
    }

    function checkSignatures(bytes32 signHash_, bytes[] calldata signatures_) external view {
        _checkSignatures(signHash_, signatures_);
    }
}
