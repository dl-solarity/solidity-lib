// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20Storage.sol";

/**
 * @dev This is modified version of OpenZeppelin's ERC20 contract to be used as a Storage contract
 * by the Diamond Standard.
 */
contract ERC20 is ERC20Storage {
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing(ERC20_STORAGE_SLOT) {
        ERC20Storage storage _erc20Storage = _erc20Storage();

        _erc20Storage.name = name_;
        _erc20Storage.symbol = symbol_;
    }

    /**
     * @dev See {IERC20-transfer}.
     */
    function transfer(address to_, uint256 amount_) public virtual override returns (bool) {
        address owner_ = _msgSender();

        _transfer(owner_, to_, amount_);

        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner_,
        address spender_
    ) public view virtual override returns (uint256) {
        return _erc20Storage().allowances[owner_][spender_];
    }

    /**
     * @dev See {IERC20-approve}.
     */
    function approve(address spender_, uint256 amount_) public virtual override returns (bool) {
        address owner_ = _msgSender();

        _approve(owner_, spender_, amount_);

        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     */
    function transferFrom(
        address from_,
        address to_,
        uint256 amount_
    ) public virtual override returns (bool) {
        address spender_ = _msgSender();

        _spendAllowance(from_, spender_, amount_);
        _transfer(from_, to_, amount_);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     */
    function increaseAllowance(
        address spender_,
        uint256 addedValue_
    ) public virtual returns (bool) {
        address owner_ = _msgSender();

        _approve(owner_, spender_, allowance(owner_, spender_) + addedValue_);

        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     */
    function decreaseAllowance(
        address spender_,
        uint256 subtractedValue_
    ) public virtual returns (bool) {
        address owner_ = _msgSender();
        uint256 currentAllowance_ = allowance(owner_, spender_);

        require(currentAllowance_ >= subtractedValue_, "ERC20: decreased allowance below zero");

        unchecked {
            _approve(owner_, spender_, currentAllowance_ - subtractedValue_);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     */
    function _transfer(address from_, address to_, uint256 amount_) internal virtual {
        require(from_ != address(0), "ERC20: transfer from the zero address");
        require(to_ != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from_, to_, amount_);

        ERC20Storage storage _erc20Storage = _erc20Storage();

        uint256 fromBalance_ = _erc20Storage.balances[from_];

        require(fromBalance_ >= amount_, "ERC20: transfer amount exceeds balance");

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
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     */
    function _mint(address account_, uint256 amount_) internal virtual {
        require(account_ != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account_, amount_);

        ERC20Storage storage _erc20Storage = _erc20Storage();

        _erc20Storage.totalSupply += amount_;

        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _erc20Storage.balances[account_] += amount_;
        }

        emit Transfer(address(0), account_, amount_);

        _afterTokenTransfer(address(0), account_, amount_);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     */
    function _burn(address account_, uint256 amount_) internal virtual {
        require(account_ != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account_, address(0), amount_);

        ERC20Storage storage _erc20Storage = _erc20Storage();

        uint256 accountBalance_ = _erc20Storage.balances[account_];
        require(accountBalance_ >= amount_, "ERC20: burn amount exceeds balance");

        unchecked {
            _erc20Storage.balances[account_] -= amount_;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _erc20Storage.totalSupply -= amount_;
        }

        emit Transfer(account_, address(0), amount_);

        _afterTokenTransfer(account_, address(0), amount_);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     */
    function _approve(address owner_, address spender_, uint256 amount_) internal virtual {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender_ != address(0), "ERC20: approve to the zero address");

        _erc20Storage().allowances[owner_][spender_] = amount_;

        emit Approval(owner_, spender_, amount_);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     */
    function _spendAllowance(address owner_, address spender_, uint256 amount_) internal virtual {
        uint256 currentAllowance_ = allowance(owner_, spender_);

        if (currentAllowance_ != type(uint256).max) {
            require(currentAllowance_ >= amount_, "ERC20: insufficient allowance");

            unchecked {
                _approve(owner_, spender_, currentAllowance_ - amount_);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     */
    function _beforeTokenTransfer(address from_, address to_, uint256 amount_) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     */
    function _afterTokenTransfer(address from_, address to_, uint256 amount_) internal virtual {}
}
