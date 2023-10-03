// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

abstract contract DiamondERC165Storage is IERC165 {
    bytes32 public constant DIAMOND_ERC165_STORAGE_SLOT =
        keccak256("diamond.standard.diamond.erc165.storage");

    struct DERC165Storage {
        mapping(bytes4 => bool) supportedInterfaces;
    }

    function _getErc165Storage() internal pure returns (DERC165Storage storage ds_) {
        bytes32 slot_ = DIAMOND_ERC165_STORAGE_SLOT;

        assembly {
            ds_.slot := slot_
        }
    }

    function supportsInterface(bytes4 interfaceId_) public view virtual override returns (bool) {
        return _getErc165Storage().supportedInterfaces[interfaceId_];
    }
}
