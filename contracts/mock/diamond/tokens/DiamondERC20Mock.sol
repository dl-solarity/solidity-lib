// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {DiamondStorage} from "../../../diamond/DiamondStorage.sol";

import "../../../diamond/tokens/ERC20/DiamondERC20.sol";

contract DiamondERC20Mock is ERC165, DiamondERC20 {
    constructor() {
        _disableInitializers(DIAMOND_ERC20_STORAGE_SLOT);
    }

    function __DiamondERC20Direct_init(string memory name_, string memory symbol_) external {
        __DiamondERC20_init(name_, symbol_);
    }

    function __DiamondERC20Mock_init(
        string memory name_,
        string memory symbol_
    ) external initializer(DIAMOND_ERC20_STORAGE_SLOT) {
        __DiamondERC20_init(name_, symbol_);
    }

    function mint(address to_, uint256 amount_) external {
        _mint(to_, amount_);
    }

    function burn(address from_, uint256 amount_) external {
        _burn(from_, amount_);
    }

    function transferMock(address from_, address to_, uint256 amount_) external {
        _transfer(from_, to_, amount_);
    }

    function approveMock(address owner_, address spender_, uint256 amount_) external {
        _approve(owner_, spender_, amount_);
    }

    function disableInitializers() external {
        _disableInitializers(DIAMOND_ERC20_STORAGE_SLOT);
    }

    function supportsInterface(bytes4 interfaceId_) public view virtual override returns (bool) {
        return
            interfaceId_ == type(DiamondStorage).interfaceId ||
            super.supportsInterface(interfaceId_);
    }
}
