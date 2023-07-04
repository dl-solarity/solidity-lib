// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../../utils/InitializableStorage.sol";

/**
 * @notice This is an ERC20 token Storage contract with Diamond Standard support
 */
abstract contract DiamondERC20Storage is InitializableStorage, Context, IERC20, IERC20Metadata {
    bytes32 public constant DIAMOND_ERC20_STORAGE_SLOT =
        keccak256("diamond.standard.diamond.erc20.storage");

    struct DiamondERC20Storage {
        string name;
        string symbol;
        uint256 totalSupply;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
    }

    function _erc20Storage() internal view returns (DiamondERC20Storage storage _erc20Storage) {
        bytes32 slot_ = DIAMOND_ERC20_STORAGE_SLOT;

        assembly {
            _erc20Storage.slot := slot_
        }
    }

    /**
     * @notice The function to get the name of the token.
     * @return The name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _erc20Storage().name;
    }

    /**
     * @notice The function to get the symbol of the token.
     * @return The symbol of the token.
     */
    function symbol() public view virtual override returns (string memory) {
        return _erc20Storage().symbol;
    }

    /**
     * @notice The function to get the number of decimals used for user representation.
     * @return The number of decimals.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @inheritdoc IERC20
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _erc20Storage().totalSupply;
    }

    /**
     * @inheritdoc IERC20
     */
    function balanceOf(address account_) public view virtual override returns (uint256) {
        return _erc20Storage().balances[account_];
    }

    /**
     * @inheritdoc IERC20
     */
    function allowance(
        address owner_,
        address spender_
    ) public view virtual override returns (uint256) {
        return _erc20Storage().allowances[owner_][spender_];
    }
}
