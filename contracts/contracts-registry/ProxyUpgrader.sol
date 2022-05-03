// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract ProxyUpgrader {
    using Address for address;

    address private immutable _owner;

    event Upgraded(address indexed proxy, address indexed implementation);

    modifier onlyOwner() {
        require(_owner == msg.sender, "ProxyUpgrader: Not an owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function upgrade(
        address what,
        address to,
        bytes calldata data
    ) external onlyOwner {
        require(to.isContract(), "ProxyUpgrader: not a contract");

        if (data.length > 0) {
            TransparentUpgradeableProxy(payable(what)).upgradeToAndCall(to, data);
        } else {
            TransparentUpgradeableProxy(payable(what)).upgradeTo(to);
        }

        emit Upgraded(what, to);
    }

    function getImplementation(address what) external view onlyOwner returns (address) {
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(what).staticcall(hex"5c60da1b");
        require(success);

        return abi.decode(returndata, (address));
    }
}
