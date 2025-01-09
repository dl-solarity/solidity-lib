// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

type uint512 is uint256;

/**
 * @notice Low-level utility library that implements unsigned 512-bit arithmetics.
 */
library U512 {
    uint256 private constant SHORT_ALLOCATION = 64;
    uint256 private constant LONG_ALLOCATION = 64;

    uint256 private constant CALL_ALLOCATION = 4 * 288;

    uint256 private constant MUL_OFFSET = 288;
    uint256 private constant EXP_OFFSET = 2 * 288;
    uint256 private constant INV_OFFSET = 3 * 288;

    function toBytes(uint512 from_) internal pure returns (bytes memory bytes_) {
        unchecked {
            uint512 handler_ = _allocate(LONG_ALLOCATION);

            assembly {
                mstore(handler_, 0x40)
                mstore(add(handler_, 0x20), mload(from_))
                mstore(add(handler_, 0x40), mload(add(from_, 0x20)))

                bytes_ := handler_
            }
        }
    }

    function isNull(uint512 handler) internal pure returns (bool isNull_) {
        unchecked {
            assembly {
                isNull_ := iszero(handler)
            }
        }
    }

    function init() internal pure returns (uint512 handler_) {
        unchecked {
            assembly {
                handler_ := 0
            }
        }
    }

    function init(uint256 from_) internal pure returns (uint512 handler_) {
        unchecked {
            handler_ = _allocate(SHORT_ALLOCATION);

            assembly {
                mstore(handler_, 0x00)
                mstore(add(0x20, handler_), from_)
            }

            return handler_;
        }
    }

    function init(bytes memory from_) internal pure returns (uint512 handler_) {
        unchecked {
            require(from_.length == 48, "U384: not 384");

            handler_ = _allocate(SHORT_ALLOCATION);

            assembly {
                mstore(handler_, 0x00)
                mstore(add(handler_, 0x10), mload(add(from_, 0x20)))
                mstore(add(handler_, 0x20), mload(add(from_, 0x30)))
            }

            return handler_;
        }
    }

    function init2(
        bytes memory from2_
    ) internal pure returns (uint512 handler1_, uint512 handler2_) {
        unchecked {
            require(from2_.length == 96, "U384: not 768");

            handler1_ = _allocate(SHORT_ALLOCATION);
            handler2_ = _allocate(SHORT_ALLOCATION);

            assembly {
                mstore(handler1_, 0x00)
                mstore(add(handler1_, 0x10), mload(add(from2_, 0x20)))
                mstore(add(handler1_, 0x20), mload(add(from2_, 0x30)))

                mstore(handler2_, 0x00)
                mstore(add(handler2_, 0x10), mload(add(from2_, 0x50)))
                mstore(add(handler2_, 0x20), mload(add(from2_, 0x60)))
            }

            return (handler1_, handler2_);
        }
    }

    function initCall(uint512 m_) internal pure returns (uint256 handler_) {
        unchecked {
            handler_ = _allocateCall(CALL_ALLOCATION);

            _sub(m_, init(2), uint512.wrap(handler_ + INV_OFFSET + 0xA0));

            assembly {
                let call_ := add(handler_, MUL_OFFSET)

                mstore(call_, 0x60)
                mstore(add(0x20, call_), 0x20)
                mstore(add(0x40, call_), 0x40)
                mstore(add(0xC0, call_), 0x01)
                mstore(add(0xE0, call_), mload(m_))
                mstore(add(0x0100, call_), mload(add(m_, 0x20)))

                call_ := add(handler_, EXP_OFFSET)

                mstore(call_, 0x40)
                mstore(add(0x20, call_), 0x20)
                mstore(add(0x40, call_), 0x40)
                mstore(add(0xC0, call_), mload(m_))
                mstore(add(0xE0, call_), mload(add(m_, 0x20)))

                call_ := add(handler_, INV_OFFSET)

                mstore(call_, 0x40)
                mstore(add(0x20, call_), 0x40)
                mstore(add(0x40, call_), 0x40)
                mstore(add(0xE0, call_), mload(m_))
                mstore(add(0x0100, call_), mload(add(m_, 0x20)))
            }
        }
    }

    function copy(uint512 handler_) internal pure returns (uint512 handlerCopy_) {
        unchecked {
            handlerCopy_ = _allocate(SHORT_ALLOCATION);

            assembly {
                mstore(handlerCopy_, mload(handler_))
                mstore(add(handlerCopy_, 0x20), mload(add(handler_, 0x20)))
            }

            return handlerCopy_;
        }
    }

    function eq(uint512 a_, uint512 b_) internal pure returns (bool eq_) {
        assembly {
            eq_ := and(eq(mload(a_), mload(b_)), eq(mload(add(a_, 0x20)), mload(add(b_, 0x20))))
        }
    }

    function eqInteger(uint512 a_, uint256 bInteger_) internal pure returns (bool eq_) {
        assembly {
            eq_ := and(eq(mload(a_), 0), eq(mload(add(a_, 0x20)), bInteger_))
        }
    }

    function cmp(uint512 a_, uint512 b_) internal pure returns (int256 cmp_) {
        unchecked {
            uint256 aWord_;
            uint256 bWord_;

            assembly {
                aWord_ := mload(a_)
                bWord_ := mload(b_)
            }

            if (aWord_ > bWord_) {
                return 1;
            }

            if (aWord_ < bWord_) {
                return -1;
            }

            assembly {
                aWord_ := mload(add(a_, 0x20))
                bWord_ := mload(add(b_, 0x20))
            }

            if (aWord_ > bWord_) {
                return 1;
            }

            if (aWord_ < bWord_) {
                return -1;
            }
        }
    }

    function modAssign(uint256 call_, uint512 a_, uint512 m_) internal view {
        assembly {
            mstore(call_, 0x40)
            mstore(add(0x20, call_), 0x20)
            mstore(add(0x40, call_), 0x40)
            mstore(add(0x60, call_), mload(a_))
            mstore(add(0x80, call_), mload(add(a_, 0x20)))
            mstore(add(0xA0, call_), 0x01)
            mstore(add(0xC0, call_), mload(m_))
            mstore(add(0xE0, call_), mload(add(m_, 0x20)))

            pop(staticcall(gas(), 0x5, call_, 0x0100, a_, 0x40))
        }
    }

    function modexp(
        uint256 call_,
        uint512 b_,
        uint256 eInteger_
    ) internal view returns (uint512 r_) {
        unchecked {
            r_ = _allocate(SHORT_ALLOCATION);

            assembly {
                call_ := add(call_, EXP_OFFSET)

                mstore(add(0x60, call_), mload(b_))
                mstore(add(0x80, call_), mload(add(b_, 0x20)))
                mstore(add(0xA0, call_), eInteger_)

                pop(staticcall(gas(), 0x5, call_, 0x0100, r_, 0x40))
            }

            return r_;
        }
    }

    function modexpAssignTo(
        uint256 call_,
        uint512 to_,
        uint512 b_,
        uint256 eInteger_
    ) internal view {
        assembly {
            call_ := add(call_, EXP_OFFSET)

            mstore(add(0x60, call_), mload(b_))
            mstore(add(0x80, call_), mload(add(b_, 0x20)))
            mstore(add(0xA0, call_), eInteger_)

            pop(staticcall(gas(), 0x5, call_, 0x0100, to_, 0x40))
        }
    }

    function modadd(uint512 a_, uint512 b_, uint512 m_) internal pure returns (uint512 r_) {
        unchecked {
            r_ = _allocate(SHORT_ALLOCATION);

            _add(a_, b_, r_);

            if (cmp(r_, m_) >= 0) {
                _subFrom(r_, m_);
            }

            return r_;
        }
    }

    function modaddAssign(uint512 a_, uint512 b_, uint512 m_) internal pure {
        unchecked {
            _addTo(a_, b_);

            if (cmp(a_, m_) >= 0) {
                return _subFrom(a_, m_);
            }
        }
    }

    function modmul(uint256 call_, uint512 a_, uint512 b_) internal view returns (uint512 r_) {
        unchecked {
            r_ = _allocate(SHORT_ALLOCATION);

            _mul(a_, b_, uint512.wrap(call_ + MUL_OFFSET + 0x60));

            assembly {
                call_ := add(call_, MUL_OFFSET)

                pop(staticcall(gas(), 0x5, call_, 0x0120, r_, 0x40))
            }

            return r_;
        }
    }

    function modmulAssign(uint256 call_, uint512 a_, uint512 b_) internal view {
        unchecked {
            _mul(a_, b_, uint512.wrap(call_ + MUL_OFFSET + 0x60));

            assembly {
                call_ := add(call_, MUL_OFFSET)

                pop(staticcall(gas(), 0x5, call_, 0x0120, a_, 0x40))
            }
        }
    }

    function modsub(uint512 a_, uint512 b_, uint512 m_) internal pure returns (uint512 r_) {
        unchecked {
            r_ = _allocate(SHORT_ALLOCATION);

            if (cmp(a_, b_) >= 0) {
                _sub(a_, b_, r_);
                return r_;
            }

            _add(a_, m_, r_);
            _subFrom(r_, b_);
        }
    }

    function modsubAssign(uint512 a_, uint512 b_, uint512 m_) internal pure {
        unchecked {
            if (cmp(a_, b_) >= 0) {
                _subFrom(a_, b_);
                return;
            }

            _addTo(a_, m_);
            _subFrom(a_, b_);
        }
    }

    function modsubAssignTo(uint512 to_, uint512 a_, uint512 b_, uint512 m_) internal pure {
        unchecked {
            if (cmp(a_, b_) >= 0) {
                _sub(a_, b_, to_);
                return;
            }

            _add(a_, m_, to_);
            _subFrom(to_, b_);
        }
    }

    function modshl1(uint512 a_, uint512 m_) internal pure returns (uint512 r_) {
        unchecked {
            r_ = _allocate(SHORT_ALLOCATION);

            _shl1(a_, r_);

            if (cmp(r_, m_) >= 0) {
                _subFrom(r_, m_);
            }

            return r_;
        }
    }

    function modshl1AssignTo(uint512 to_, uint512 a_, uint512 m_) internal pure {
        unchecked {
            _shl1(a_, to_);

            if (cmp(to_, m_) >= 0) {
                _subFrom(to_, m_);
            }
        }
    }

    /// @dev Stores modinv into `b_` and moddiv into `a_`.
    function moddivAssign(uint256 call_, uint512 a_, uint512 b_) internal view {
        unchecked {
            assembly {
                call_ := add(call_, INV_OFFSET)

                mstore(add(0x60, call_), mload(b_))
                mstore(add(0x80, call_), mload(add(b_, 0x20)))

                pop(staticcall(gas(), 0x5, call_, 0x0120, b_, 0x40))
            }

            modmulAssign(call_ - INV_OFFSET, a_, b_);
        }
    }

    function moddiv(
        uint256 call_,
        uint512 a_,
        uint512 b_,
        uint512 m_
    ) internal view returns (uint512 r_) {
        unchecked {
            r_ = modinv(call_, b_, m_);

            _mul(a_, r_, uint512.wrap(call_ + 0x60));

            assembly {
                mstore(call_, 0x60)
                mstore(add(0x20, call_), 0x20)
                mstore(add(0x40, call_), 0x40)
                mstore(add(0xC0, call_), 0x01)
                mstore(add(0xE0, call_), mload(m_))
                mstore(add(0x0100, call_), mload(add(m_, 0x20)))

                pop(staticcall(gas(), 0x5, call_, 0x0120, r_, 0x40))
            }
        }
    }

    function modinv(uint256 call_, uint512 b_, uint512 m_) internal view returns (uint512 r_) {
        unchecked {
            r_ = _allocate(SHORT_ALLOCATION);

            _sub(m_, init(2), uint512.wrap(call_ + 0xA0));

            assembly {
                mstore(call_, 0x40)
                mstore(add(0x20, call_), 0x40)
                mstore(add(0x40, call_), 0x40)
                mstore(add(0x60, call_), mload(b_))
                mstore(add(0x80, call_), mload(add(b_, 0x20)))
                mstore(add(0xE0, call_), mload(m_))
                mstore(add(0x0100, call_), mload(add(m_, 0x20)))

                pop(staticcall(gas(), 0x5, call_, 0x0120, r_, 0x40))
            }
        }
    }

    function _shl1(uint512 a_, uint512 r_) internal pure {
        assembly {
            let a1_ := mload(add(a_, 0x20))

            mstore(r_, or(shl(1, mload(a_)), shr(255, a1_)))
            mstore(add(r_, 0x20), shl(1, a1_))
        }
    }

    function _add(uint512 a_, uint512 b_, uint512 r_) private pure {
        assembly {
            let aWord_ := mload(add(a_, 0x20))
            let sum_ := add(aWord_, mload(add(b_, 0x20)))

            mstore(add(r_, 0x20), sum_)

            sum_ := gt(aWord_, sum_)
            sum_ := add(sum_, add(mload(a_), mload(b_)))

            mstore(r_, sum_)
        }
    }

    function _sub(uint512 a_, uint512 b_, uint512 r_) private pure {
        assembly {
            let aWord_ := mload(add(a_, 0x20))
            let diff_ := sub(aWord_, mload(add(b_, 0x20)))

            mstore(add(r_, 0x20), diff_)

            diff_ := gt(diff_, aWord_)
            diff_ := sub(sub(mload(a_), mload(b_)), diff_)

            mstore(r_, diff_)
        }
    }

    function _subFrom(uint512 a_, uint512 b_) private pure {
        assembly {
            let aWord_ := mload(add(a_, 0x20))
            let diff_ := sub(aWord_, mload(add(b_, 0x20)))

            mstore(add(a_, 0x20), diff_)

            diff_ := gt(diff_, aWord_)
            diff_ := sub(sub(mload(a_), mload(b_)), diff_)

            mstore(a_, diff_)
        }
    }

    function _addTo(uint512 a_, uint512 b_) private pure {
        assembly {
            let aWord_ := mload(add(a_, 0x20))
            let sum_ := add(aWord_, mload(add(b_, 0x20)))

            mstore(add(a_, 0x20), sum_)

            sum_ := gt(aWord_, sum_)
            sum_ := add(sum_, add(mload(a_), mload(b_)))

            mstore(a_, sum_)
        }
    }

    function _mul(uint512 a_, uint512 b_, uint512 r_) private pure {
        assembly {
            let a0_ := mload(a_)
            let a1_ := shr(128, mload(add(a_, 0x20)))
            let a2_ := and(mload(add(a_, 0x20)), 0xffffffffffffffffffffffffffffffff)

            let b0_ := mload(b_)
            let b1_ := shr(128, mload(add(b_, 0x20)))
            let b2_ := and(mload(add(b_, 0x20)), 0xffffffffffffffffffffffffffffffff)

            // r5
            let current_ := mul(a2_, b2_)
            let r0_ := and(current_, 0xffffffffffffffffffffffffffffffff)

            // r4
            current_ := shr(128, current_)

            let temp_ := mul(a1_, b2_)
            current_ := add(current_, temp_)
            let curry_ := lt(current_, temp_)

            temp_ := mul(a2_, b1_)
            current_ := add(current_, temp_)
            curry_ := add(curry_, lt(current_, temp_))

            mstore(add(r_, 0x40), add(shl(128, current_), r0_))

            // r3
            current_ := add(shl(128, curry_), shr(128, current_))
            curry_ := 0

            temp_ := mul(a0_, b2_)
            current_ := add(current_, temp_)
            curry_ := lt(current_, temp_)

            temp_ := mul(a1_, b1_)
            current_ := add(current_, temp_)
            curry_ := add(curry_, lt(current_, temp_))

            temp_ := mul(a2_, b0_)
            current_ := add(current_, temp_)
            curry_ := add(curry_, lt(current_, temp_))

            r0_ := and(current_, 0xffffffffffffffffffffffffffffffff)

            // r2
            current_ := add(shl(128, curry_), shr(128, current_))
            curry_ := 0

            temp_ := mul(a0_, b1_)
            current_ := add(current_, temp_)
            curry_ := lt(current_, temp_)

            temp_ := mul(a1_, b0_)
            current_ := add(current_, temp_)
            curry_ := add(curry_, lt(current_, temp_))

            mstore(add(r_, 0x20), add(shl(128, current_), r0_))

            // r1
            current_ := add(shl(128, curry_), shr(128, current_))
            current_ := add(current_, mul(a0_, b0_))

            mstore(r_, current_)
        }
    }

    function _allocate(uint256 bytes_) private pure returns (uint512 handler_) {
        unchecked {
            assembly {
                handler_ := mload(0x40)
                mstore(0x40, add(handler_, bytes_))
            }

            return handler_;
        }
    }

    function _allocateCall(uint256 bytes_) private pure returns (uint256 handler_) {
        unchecked {
            assembly {
                handler_ := mload(0x40)
                mstore(0x40, add(handler_, bytes_))
            }

            return handler_;
        }
    }
}
