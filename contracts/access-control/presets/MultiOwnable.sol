// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../AbstractMultiOwnable.sol";

contract MultiOwnable is AbstractMultiOwnable {
    function __MultiOwnable_init() external initializer {        
        __AbstractMultiOwnable_init();     
    }
}