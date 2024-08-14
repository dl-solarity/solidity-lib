// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import {DiamondERC20Storage} from "./DiamondERC20Storage.sol";

/**
 * @notice The Diamond standard module
 *
 * This is modified version of OpenZeppelin's ERC20 contract to be used as a Storage contract
 * by the Diamond Standard.
 */
contract DiamondERC20 is DiamondERC20Storage, IERC20Errors {
    /**
     * @notice Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18.
     */
    function __DiamondERC20_init(
        string memory name_,
        string memory symbol_
    ) internal onlyInitializing(DIAMOND_ERC20_STORAGE_SLOT) {
        DERC20Storage storage _erc20Storage = _getErc20Storage();

        _erc20Storage.name = name_;
        _erc20Storage.symbol = symbol_;
    }

    /**
     * @inheritdoc IERC20
     */
    function transfer(address to_, uint256 amount_) public virtual override returns (bool) {
        _transfer(msg.sender, to_, amount_);

        return true;
    }

    /**
     * @inheritdoc IERC20
     */
    function approve(address spender_, uint256 amount_) public virtual override returns (bool) {
        _approve(msg.sender, spender_, amount_);

        return true;
    }

    /**
     * @inheritdoc IERC20
     */
    function transferFrom(
        address from_,
        address to_,
        uint256 amount_
    ) public virtual override returns (bool) {
        _spendAllowance(from_, msg.sender, amount_);
        _transfer(from_, to_, amount_);

        return true;
    }

    /**
     * @notice Moves `amount` of tokens from `from` to `to`.
     */
    function _transfer(address from_, address to_, uint256 amount_) internal virtual {
        if (from_ == address(0)) {
            revert ERC20InvalidSender(address(0));
        }

        if (to_ == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }

        _beforeTokenTransfer(from_, to_, amount_);

        DERC20Storage storage _erc20Storage = _getErc20Storage();

        uint256 fromBalance_ = _erc20Storage.balances[from_];

        if (fromBalance_ < amount_) {
            revert ERC20InsufficientBalance(from_, fromBalance_, amount_);
        }

        unchecked {
            _erc20Storage.balances[from_] = fromBalance_ - amount_;

            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _erc20Storage.balances[to_] += amount_;
        }

        emit Transfer(from_, to_, amount_);

        _afterTokenTransfer(from_, to_, amount_);
    }

    /**
     * @notice Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     */
    function _mint(address account_, uint256 amount_) internal virtual {
        if (account_ == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }

        _beforeTokenTransfer(address(0), account_, amount_);

        DERC20Storage storage _erc20Storage = _getErc20Storage();

        _erc20Storage.totalSupply += amount_;

        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _erc20Storage.balances[account_] += amount_;
        }

        emit Transfer(address(0), account_, amount_);

        _afterTokenTransfer(address(0), account_, amount_);
    }

    /**
     * @notice Destroys `amount` tokens from `account`, reducing the
     * total supply.
     */
    function _burn(address account_, uint256 amount_) internal virtual {
        if (account_ == address(0)) {
            revert ERC20InvalidSender(address(0));
        }

        _beforeTokenTransfer(account_, address(0), amount_);

        DERC20Storage storage _erc20Storage = _getErc20Storage();

        uint256 accountBalance_ = _erc20Storage.balances[account_];
        if (accountBalance_ < amount_) {
            revert ERC20InsufficientBalance(account_, accountBalance_, amount_);
        }

        unchecked {
            _erc20Storage.balances[account_] -= amount_;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _erc20Storage.totalSupply -= amount_;
        }

        emit Transfer(account_, address(0), amount_);

        _afterTokenTransfer(account_, address(0), amount_);
    }

    /**
     * @notice Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     */
    function _approve(address owner_, address spender_, uint256 amount_) internal virtual {
        if (owner_ == address(0)) {
            revert ERC20InvalidApprover(owner_);
        }

        if (spender_ == address(0)) {
            revert ERC20InvalidSpender(spender_);
        }

        _getErc20Storage().allowances[owner_][spender_] = amount_;

        emit Approval(owner_, spender_, amount_);
    }

    /**
     * @notice Updates `owner` s allowance for `spender` based on spent `amount`.
     */
    function _spendAllowance(address owner_, address spender_, uint256 amount_) internal virtual {
        uint256 currentAllowance_ = allowance(owner_, spender_);

        if (currentAllowance_ != type(uint256).max) {
            if (currentAllowance_ < amount_) {
                revert ERC20InsufficientAllowance(spender_, currentAllowance_, amount_);
            }

            unchecked {
                _approve(owner_, spender_, currentAllowance_ - amount_);
            }
        }
    }

    /**
     * @notice Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     */
    function _beforeTokenTransfer(address from_, address to_, uint256 amount_) internal virtual {}

    /**
     * @notice Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     */
    function _afterTokenTransfer(address from_, address to_, uint256 amount_) internal virtual {}
}
