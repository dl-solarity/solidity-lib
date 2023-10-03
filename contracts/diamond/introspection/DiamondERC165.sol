// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./DiamondERC165Storage.sol";

contract DiamondERC165 is DiamondERC165Storage {
    function registerInterface(bytes4 interfaceId_) public virtual {
        require(interfaceId_ != 0xffffffff, "ERC165: invalid interface id");
        _getErc165Storage().supportedInterfaces[interfaceId_] = true;
    }
}
