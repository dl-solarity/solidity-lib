// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {DiamondERC721Storage} from "./DiamondERC721Storage.sol";

/**
 * @notice This is modified version of OpenZeppelin's ERC721 contract to be used as a Storage contract
 * by the Diamond Standard.
 */
contract DiamondERC721 is DiamondERC721Storage {
    using Address for address;

    /**
     * @notice Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18.
     */
    function __DiamondERC721_init(
        string memory name_,
        string memory symbol_
    ) internal onlyInitializing(DIAMOND_ERC721_STORAGE_SLOT) {
        DERC721Storage storage _erc721Storage = _getErc721Storage();

        _erc721Storage.name = name_;
        _erc721Storage.symbol = symbol_;
    }

    /**
     * @inheritdoc IERC721
     */
    function approve(address to_, uint256 tokenId_) public virtual override {
        address owner = ownerOf(tokenId_);
        require(to_ != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to_, tokenId_);
    }

    /**
     * @inheritdoc IERC721
     */
    function setApprovalForAll(address operator_, bool approved_) public virtual override {
        _setApprovalForAll(_msgSender(), operator_, approved_);
    }

    /**
     * @inheritdoc IERC721
     */
    function transferFrom(address from_, address to_, uint256 tokenId_) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId_),
            "ERC721: caller is not token owner or approved"
        );

        _transfer(from_, to_, tokenId_);
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public virtual override {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId_),
            "ERC721: caller is not token owner or approved"
        );
        _safeTransfer(from_, to_, tokenId_, data_);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) internal virtual {
        _transfer(from_, to_, tokenId_);
        require(
            _checkOnERC721Received(from_, to_, tokenId_, data_),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to_, uint256 tokenId_) internal virtual {
        _safeMint(to_, tokenId_, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to_, uint256 tokenId_, bytes memory data_) internal virtual {
        _mint(to_, tokenId_);
        require(
            _checkOnERC721Received(address(0), to_, tokenId_, data_),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to_, uint256 tokenId_) internal virtual {
        require(to_ != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId_), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to_, tokenId_, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId_), "ERC721: token already minted");

        DERC721Storage storage _erc721Storage = _getErc721Storage();

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _erc721Storage.balances[to_] += 1;
        }

        _erc721Storage.owners[tokenId_] = to_;

        emit Transfer(address(0), to_, tokenId_);

        _afterTokenTransfer(address(0), to_, tokenId_, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId_) internal virtual {
        address owner = ownerOf(tokenId_);

        _beforeTokenTransfer(owner, address(0), tokenId_, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ownerOf(tokenId_);

        DERC721Storage storage _erc721Storage = _getErc721Storage();

        // Clear approvals
        delete _erc721Storage.tokenApprovals[tokenId_];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _erc721Storage.balances[owner] -= 1;
        }
        delete _erc721Storage.owners[tokenId_];

        emit Transfer(owner, address(0), tokenId_);

        _afterTokenTransfer(owner, address(0), tokenId_, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from_, address to_, uint256 tokenId_) internal virtual {
        require(ownerOf(tokenId_) == from_, "ERC721: transfer from incorrect owner");
        require(to_ != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from_, to_, tokenId_, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ownerOf(tokenId_) == from_, "ERC721: transfer from incorrect owner");

        DERC721Storage storage _erc721Storage = _getErc721Storage();

        // Clear approvals from the previous owner
        delete _erc721Storage.tokenApprovals[tokenId_];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _erc721Storage.balances[from_] -= 1;
            _erc721Storage.balances[to_] += 1;
        }
        _getErc721Storage().owners[tokenId_] = to_;

        emit Transfer(from_, to_, tokenId_);

        _afterTokenTransfer(from_, to_, tokenId_, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to_, uint256 tokenId_) internal virtual {
        _getErc721Storage().tokenApprovals[tokenId_] = to_;
        emit Approval(ownerOf(tokenId_), to_, tokenId_);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner_,
        address operator_,
        bool approved_
    ) internal virtual {
        require(owner_ != operator_, "ERC721: approve to caller");
        _getErc721Storage().operatorApprovals[owner_][operator_] = approved_;
        emit ApprovalForAll(owner_, operator_, approved_);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from_ address representing the previous owner of the given token ID
     * @param to_ target address that will receive the tokens
     * @param tokenId_ uint256 ID of the token to be transferred
     * @param data_ bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) private returns (bool) {
        if (to_.isContract()) {
            try
                IERC721Receiver(to_).onERC721Received(_msgSender(), from_, tokenId_, data_)
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 firstTokenId_,
        uint256 batchSize_
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from_,
        address to_,
        uint256 firstTokenId_,
        uint256 batchSize_
    ) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account_, uint256 amount_) internal {
        _getErc721Storage().balances[account_] += amount_;
    }
}
