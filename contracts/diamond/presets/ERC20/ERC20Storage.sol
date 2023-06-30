// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../../utils/InitializableStorage.sol";

/**
 * @dev This is an ERC20 token Storage contract with Diamond Standard support
 */
abstract contract ERC20Storage is InitializableStorage, Context, IERC20, IERC20Metadata {
    bytes32 public constant ERC20_STORAGE_SLOT = keccak256("diamond.standard.erc20.storage");

    struct ERC20Storage {
        string name;
        string symbol;
        uint256 totalSupply;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
    }

    function _erc20Storage() internal view returns (ERC20Storage storage _erc20Storage) {
        bytes32 slot_ = ERC20_STORAGE_SLOT;

        assembly {
            _erc20Storage.slot := slot_
        }
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _erc20Storage().name;
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() public view virtual override returns (string memory) {
        return _erc20Storage().symbol;
    }

    /**
     * @dev The function returns the number of decimals used for user representation.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _erc20Storage().totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account_) public view virtual override returns (uint256) {
        return _erc20Storage().balances[account_];
    }
}
