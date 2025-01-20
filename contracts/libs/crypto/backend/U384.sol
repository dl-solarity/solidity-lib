// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @notice Low-level utility library that implements unsigned 384-bit arithmetics.
 *
 * Serves for internal purposes only.
 */
library _U384 {
    uint256 private constant _UINT384_ALLOCATION = 64;
    uint256 private constant _CALL_ALLOCATION = 4 * 288;
    uint256 private constant _MUL_OFFSET = 288;
    uint256 private constant _EXP_OFFSET = 2 * 288;
    uint256 private constant _INV_OFFSET = 3 * 288;

    function initCall(uint256 m_) internal pure returns (uint256 handler_) {
        unchecked {
            handler_ = _allocate(_CALL_ALLOCATION);

            _sub(m_, fromUint256(2), handler_ + _INV_OFFSET + 0xA0);

            assembly {
                let call_ := add(handler_, _MUL_OFFSET)

                mstore(call_, 0x60)
                mstore(add(0x20, call_), 0x20)
                mstore(add(0x40, call_), 0x40)
                mstore(add(0xC0, call_), 0x01)
                mstore(add(0xE0, call_), mload(m_))
                mstore(add(0x0100, call_), mload(add(m_, 0x20)))

                call_ := add(handler_, _EXP_OFFSET)

                mstore(call_, 0x40)
                mstore(add(0x20, call_), 0x20)
                mstore(add(0x40, call_), 0x40)
                mstore(add(0xC0, call_), mload(m_))
                mstore(add(0xE0, call_), mload(add(m_, 0x20)))

                call_ := add(handler_, _INV_OFFSET)

                mstore(call_, 0x40)
                mstore(add(0x20, call_), 0x40)
                mstore(add(0x40, call_), 0x40)
                mstore(add(0xE0, call_), mload(m_))
                mstore(add(0x0100, call_), mload(add(m_, 0x20)))
            }
        }
    }

    function fromUint256(uint256 u256_) internal pure returns (uint256 handler_) {
        unchecked {
            handler_ = _allocate(_UINT384_ALLOCATION);

            assembly {
                mstore(handler_, 0x00)
                mstore(add(handler_, 0x20), u256_)
            }
        }
    }

    function fromBytes(bytes memory bytes_) internal view returns (uint256 handler_) {
        unchecked {
            assert(bytes_.length < 49);

            handler_ = _allocate(_UINT384_ALLOCATION);

            assembly {
                mstore(handler_, 0)
                mstore(add(handler_, 0x20), 0)

                let size_ := mload(bytes_)
                pop(
                    staticcall(
                        gas(),
                        0x4,
                        add(bytes_, 0x20),
                        size_,
                        add(handler_, sub(0x40, size_)),
                        size_
                    )
                )
            }
        }
    }

    function copy(uint256 handler_) internal pure returns (uint256 handlerCopy_) {
        unchecked {
            handlerCopy_ = _allocate(_UINT384_ALLOCATION);

            assembly {
                mstore(handlerCopy_, mload(handler_))
                mstore(add(handlerCopy_, 0x20), mload(add(handler_, 0x20)))
            }

            return handlerCopy_;
        }
    }

    function eq(uint256 a_, uint256 b_) internal pure returns (bool eq_) {
        assembly {
            eq_ := and(eq(mload(a_), mload(b_)), eq(mload(add(a_, 0x20)), mload(add(b_, 0x20))))
        }
    }

    function eqUint256(uint256 a_, uint256 bInteger_) internal pure returns (bool eq_) {
        assembly {
            eq_ := and(eq(mload(a_), 0), eq(mload(add(a_, 0x20)), bInteger_))
        }
    }

    function cmp(uint256 a_, uint256 b_) internal pure returns (int256) {
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

            return 0;
        }
    }

    function modAssign(uint256 call_, uint256 a_, uint256 m_) internal view {
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
        uint256 b_,
        uint256 eInteger_
    ) internal view returns (uint256 r_) {
        unchecked {
            r_ = _allocate(_UINT384_ALLOCATION);

            assembly {
                call_ := add(call_, _EXP_OFFSET)

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
        uint256 to_,
        uint256 b_,
        uint256 eInteger_
    ) internal view {
        assembly {
            call_ := add(call_, _EXP_OFFSET)

            mstore(add(0x60, call_), mload(b_))
            mstore(add(0x80, call_), mload(add(b_, 0x20)))
            mstore(add(0xA0, call_), eInteger_)

            pop(staticcall(gas(), 0x5, call_, 0x0100, to_, 0x40))
        }
    }

    function modadd(uint256 a_, uint256 b_, uint256 m_) internal pure returns (uint256 r_) {
        unchecked {
            r_ = _allocate(_UINT384_ALLOCATION);

            _add(a_, b_, r_);

            if (cmp(r_, m_) >= 0) {
                _subFrom(r_, m_);
            }

            return r_;
        }
    }

    function modaddAssign(uint256 a_, uint256 b_, uint256 m_) internal pure {
        unchecked {
            _addTo(a_, b_);

            if (cmp(a_, m_) >= 0) {
                return _subFrom(a_, m_);
            }
        }
    }

    function modmul(uint256 call_, uint256 a_, uint256 b_) internal view returns (uint256 r_) {
        unchecked {
            r_ = _allocate(_UINT384_ALLOCATION);

            _mul(a_, b_, call_ + _MUL_OFFSET + 0x60);

            assembly {
                call_ := add(call_, _MUL_OFFSET)

                pop(staticcall(gas(), 0x5, call_, 0x0120, r_, 0x40))
            }

            return r_;
        }
    }

    function modmulAssign(uint256 call_, uint256 a_, uint256 b_) internal view {
        unchecked {
            _mul(a_, b_, call_ + _MUL_OFFSET + 0x60);

            assembly {
                call_ := add(call_, _MUL_OFFSET)

                pop(staticcall(gas(), 0x5, call_, 0x0120, a_, 0x40))
            }
        }
    }

    function modsub(uint256 a_, uint256 b_, uint256 m_) internal pure returns (uint256 r_) {
        unchecked {
            r_ = _allocate(_UINT384_ALLOCATION);

            if (cmp(a_, b_) >= 0) {
                _sub(a_, b_, r_);
                return r_;
            }

            _add(a_, m_, r_);
            _subFrom(r_, b_);
        }
    }

    function modsubAssign(uint256 a_, uint256 b_, uint256 m_) internal pure {
        unchecked {
            if (cmp(a_, b_) >= 0) {
                _subFrom(a_, b_);
                return;
            }

            _addTo(a_, m_);
            _subFrom(a_, b_);
        }
    }

    function modsubAssignTo(uint256 to_, uint256 a_, uint256 b_, uint256 m_) internal pure {
        unchecked {
            if (cmp(a_, b_) >= 0) {
                _sub(a_, b_, to_);
                return;
            }

            _add(a_, m_, to_);
            _subFrom(to_, b_);
        }
    }

    function modshl1(uint256 a_, uint256 m_) internal pure returns (uint256 r_) {
        unchecked {
            r_ = _allocate(_UINT384_ALLOCATION);

            _shl1(a_, r_);

            if (cmp(r_, m_) >= 0) {
                _subFrom(r_, m_);
            }

            return r_;
        }
    }

    function modshl1AssignTo(uint256 to_, uint256 a_, uint256 m_) internal pure {
        unchecked {
            _shl1(a_, to_);

            if (cmp(to_, m_) >= 0) {
                _subFrom(to_, m_);
            }
        }
    }

    /// @dev Stores modinv into `b_` and moddiv into `a_`.
    function moddivAssign(uint256 call_, uint256 a_, uint256 b_) internal view {
        unchecked {
            assembly {
                call_ := add(call_, _INV_OFFSET)

                mstore(add(0x60, call_), mload(b_))
                mstore(add(0x80, call_), mload(add(b_, 0x20)))

                pop(staticcall(gas(), 0x5, call_, 0x0120, b_, 0x40))
            }

            modmulAssign(call_ - _INV_OFFSET, a_, b_);
        }
    }

    function moddiv(
        uint256 call_,
        uint256 a_,
        uint256 b_,
        uint256 m_
    ) internal view returns (uint256 r_) {
        unchecked {
            r_ = modinv(call_, b_, m_);

            _mul(a_, r_, call_ + 0x60);

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

    function modinv(uint256 call_, uint256 b_, uint256 m_) internal view returns (uint256 r_) {
        unchecked {
            r_ = _allocate(_UINT384_ALLOCATION);

            _sub(m_, fromUint256(2), call_ + 0xA0);

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

    function _shl1(uint256 a_, uint256 r_) internal pure {
        assembly {
            let a1_ := mload(add(a_, 0x20))

            mstore(r_, or(shl(1, mload(a_)), shr(255, a1_)))
            mstore(add(r_, 0x20), shl(1, a1_))
        }
    }

    function _add(uint256 a_, uint256 b_, uint256 r_) private pure {
        assembly {
            let aWord_ := mload(add(a_, 0x20))
            let sum_ := add(aWord_, mload(add(b_, 0x20)))

            mstore(add(r_, 0x20), sum_)

            sum_ := gt(aWord_, sum_)
            sum_ := add(sum_, add(mload(a_), mload(b_)))

            mstore(r_, sum_)
        }
    }

    function _sub(uint256 a_, uint256 b_, uint256 r_) private pure {
        assembly {
            let aWord_ := mload(add(a_, 0x20))
            let diff_ := sub(aWord_, mload(add(b_, 0x20)))

            mstore(add(r_, 0x20), diff_)

            diff_ := gt(diff_, aWord_)
            diff_ := sub(sub(mload(a_), mload(b_)), diff_)

            mstore(r_, diff_)
        }
    }

    function _subFrom(uint256 a_, uint256 b_) private pure {
        assembly {
            let aWord_ := mload(add(a_, 0x20))
            let diff_ := sub(aWord_, mload(add(b_, 0x20)))

            mstore(add(a_, 0x20), diff_)

            diff_ := gt(diff_, aWord_)
            diff_ := sub(sub(mload(a_), mload(b_)), diff_)

            mstore(a_, diff_)
        }
    }

    function _addTo(uint256 a_, uint256 b_) private pure {
        assembly {
            let aWord_ := mload(add(a_, 0x20))
            let sum_ := add(aWord_, mload(add(b_, 0x20)))

            mstore(add(a_, 0x20), sum_)

            sum_ := gt(aWord_, sum_)
            sum_ := add(sum_, add(mload(a_), mload(b_)))

            mstore(a_, sum_)
        }
    }

    function _mul(uint256 a_, uint256 b_, uint256 r_) private pure {
        unchecked {
            assembly {
                let a0_ := mload(a_)
                let a1_ := mload(add(a_, 0x20))
                let b0_ := mload(b_)
                let b1_ := mload(add(b_, 0x20))

                let mm_ := mulmod(
                    a1_,
                    b1_,
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                )
                let c3_ := mul(a1_, b1_)
                let c2_ := sub(sub(mm_, c3_), lt(mm_, c3_))

                mm_ := mulmod(
                    a0_,
                    b1_,
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                )
                let prod1_ := mul(a0_, b1_)
                let prod0_ := sub(sub(mm_, prod1_), lt(mm_, prod1_))

                c2_ := add(c2_, prod1_)
                let c1_ := lt(c2_, prod1_)
                c1_ := add(c1_, prod0_)

                mm_ := mulmod(
                    a1_,
                    b0_,
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                )
                prod1_ := mul(a1_, b0_)
                prod0_ := sub(sub(mm_, prod1_), lt(mm_, prod1_))

                c2_ := add(c2_, prod1_)
                c1_ := add(c1_, lt(c2_, prod1_))
                c1_ := add(c1_, prod0_)
                c1_ := add(c1_, mul(a0_, b0_))

                mstore(add(r_, 0x40), c3_)
                mstore(add(r_, 0x20), c2_)
                mstore(r_, c1_)
            }
        }
    }

    function _allocate(uint256 bytes_) private pure returns (uint256 handler_) {
        unchecked {
            assembly {
                handler_ := mload(0x40)
                mstore(0x40, add(handler_, bytes_))
            }

            return handler_;
        }
    }
}
