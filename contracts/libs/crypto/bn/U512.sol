// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

type uint512 is uint256;
type call is uint256;

/**
 * @notice Low-level library that implements unsigned 512-bit arithmetics.
 */
library U512 {
    uint256 private constant _UINT512_ALLOCATION = 64;
    uint256 private constant _BYTES_ALLOCATION = 96;
    uint256 private constant _CALL_ALLOCATION = 384;

    function initCall() internal pure returns (call call_) {
        unchecked {
            call_ = call.wrap(_allocate(_CALL_ALLOCATION));
        }
    }

    function fromUint256(uint256 u256_) internal pure returns (uint512 u512_) {
        unchecked {
            u512_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            assembly {
                mstore(u512_, 0x00)
                mstore(add(u512_, 0x20), u256_)
            }
        }
    }

    function fromBytes(bytes memory bytes_) internal view returns (uint512 u512_) {
        unchecked {
            assert(bytes_.length < 65);

            u512_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            assembly {
                mstore(u512_, 0)
                mstore(add(u512_, 0x20), 0)

                let size_ := mload(bytes_)
                pop(
                    staticcall(
                        gas(),
                        0x4,
                        add(bytes_, 0x20),
                        size_,
                        add(u512_, sub(0x40, size_)),
                        size_
                    )
                )
            }
        }
    }

    function copy(uint512 u512_) internal pure returns (uint512 u512Copy_) {
        unchecked {
            u512Copy_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            assembly {
                mstore(u512Copy_, mload(u512_))
                mstore(add(u512Copy_, 0x20), mload(add(u512_, 0x20)))
            }
        }
    }

    function toBytes(uint512 u512_) internal pure returns (bytes memory bytes_) {
        unchecked {
            uint256 handler_ = _allocate(_BYTES_ALLOCATION);

            assembly {
                mstore(handler_, 0x40)
                mstore(add(handler_, 0x20), mload(u512_))
                mstore(add(handler_, 0x40), mload(add(u512_, 0x20)))

                bytes_ := handler_
            }
        }
    }

    function isNull(uint512 u512_) internal pure returns (bool isNull_) {
        unchecked {
            assembly {
                isNull_ := iszero(u512_)
            }
        }
    }

    function eq(uint512 a_, uint512 b_) internal pure returns (bool eq_) {
        unchecked {
            assembly {
                eq_ := and(
                    eq(mload(a_), mload(b_)),
                    eq(mload(add(a_, 0x20)), mload(add(b_, 0x20)))
                )
            }
        }
    }

    function eqUint256(uint512 a_, uint256 u256_) internal pure returns (bool eq_) {
        unchecked {
            assembly {
                eq_ := and(eq(mload(a_), 0), eq(mload(add(a_, 0x20)), u256_))
            }
        }
    }

    function cmp(uint512 a_, uint512 b_) internal pure returns (int256) {
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

    function mod(call call_, uint512 a_, uint512 m_) internal view returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            _mod(call_, a_, m_, r_);
        }
    }

    function modAssign(call call_, uint512 a_, uint512 m_) internal view {
        unchecked {
            _mod(call_, a_, m_, a_);
        }
    }

    function modAssignTo(call call_, uint512 a_, uint512 m_, uint512 to_) internal view {
        unchecked {
            _mod(call_, a_, m_, to_);
        }
    }

    function modinv(call call_, uint512 a_, uint512 m_) internal view returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            _modinv(call_, a_, m_, r_);
        }
    }

    function modinvAssign(call call_, uint512 a_, uint512 m_) internal view {
        unchecked {
            _modinv(call_, a_, m_, a_);
        }
    }

    function modinvAssignTo(call call_, uint512 a_, uint512 m_, uint512 to_) internal view {
        unchecked {
            _modinv(call_, a_, m_, to_);
        }
    }

    function modexp(
        call call_,
        uint512 b_,
        uint512 e_,
        uint512 m_
    ) internal view returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            _modexp(call_, b_, e_, m_, r_);
        }
    }

    function modexpAssign(call call_, uint512 b_, uint512 e_, uint512 m_) internal view {
        unchecked {
            _modexp(call_, b_, e_, m_, b_);
        }
    }

    function modexpAssignTo(
        call call_,
        uint512 b_,
        uint512 e_,
        uint512 m_,
        uint512 to_
    ) internal view {
        unchecked {
            _modexp(call_, b_, e_, m_, to_);
        }
    }

    function modadd(
        call call_,
        uint512 a_,
        uint512 b_,
        uint512 m_
    ) internal view returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            _modadd(call_, a_, b_, m_, r_);
        }
    }

    function modaddAssign(call call_, uint512 a_, uint512 b_, uint512 m_) internal view {
        unchecked {
            _modadd(call_, a_, b_, m_, a_);
        }
    }

    function modaddAssignTo(
        call call_,
        uint512 a_,
        uint512 b_,
        uint512 m_,
        uint512 to_
    ) internal view {
        unchecked {
            _modadd(call_, a_, b_, m_, to_);
        }
    }

    function add(uint512 a_, uint512 b_) internal pure returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            _add(a_, b_, r_);
        }
    }

    function addAssign(uint512 a_, uint512 b_) internal pure {
        unchecked {
            _add(a_, b_, a_);
        }
    }

    function addAssignTo(uint512 a_, uint512 b_, uint512 to_) internal pure {
        unchecked {
            _add(a_, b_, to_);
        }
    }

    function modsub(
        call call_,
        uint512 a_,
        uint512 b_,
        uint512 m_
    ) internal view returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            _modsub(call_, a_, b_, m_, r_);
        }
    }

    function modsubAssign(call call_, uint512 a_, uint512 b_, uint512 m_) internal view {
        unchecked {
            _modsub(call_, a_, b_, m_, a_);
        }
    }

    function modsubAssignTo(
        call call_,
        uint512 a_,
        uint512 b_,
        uint512 m_,
        uint512 to_
    ) internal view {
        unchecked {
            _modsub(call_, a_, b_, m_, to_);
        }
    }

    function sub(uint512 a_, uint512 b_) internal pure returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            _sub(a_, b_, r_);
        }
    }

    function subAssign(uint512 a_, uint512 b_) internal pure {
        unchecked {
            _sub(a_, b_, a_);
        }
    }

    function subAssignTo(uint512 a_, uint512 b_, uint512 to_) internal pure {
        unchecked {
            _sub(a_, b_, to_);
        }
    }

    function modmul(
        call call_,
        uint512 a_,
        uint512 b_,
        uint512 m_
    ) internal view returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            _modmul(call_, a_, b_, m_, r_);
        }
    }

    function modmulAssign(call call_, uint512 a_, uint512 b_, uint512 m_) internal view {
        unchecked {
            _modmul(call_, a_, b_, m_, a_);
        }
    }

    function modmulAssignTo(
        call call_,
        uint512 a_,
        uint512 b_,
        uint512 m_,
        uint512 to_
    ) internal view {
        unchecked {
            _modmul(call_, a_, b_, m_, to_);
        }
    }

    function mul(uint512 a_, uint512 b_) internal pure returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            _mul(a_, b_, r_);
        }
    }

    function mulAssign(uint512 a_, uint512 b_) internal pure {
        unchecked {
            _mul(a_, b_, a_);
        }
    }

    function mulAssignTo(uint512 a_, uint512 b_, uint512 to_) internal pure {
        unchecked {
            _mul(a_, b_, to_);
        }
    }

    function moddiv(
        call call_,
        uint512 a_,
        uint512 b_,
        uint512 m_
    ) internal view returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            _moddiv(call_, a_, b_, m_, r_);
        }
    }

    function moddivAssign(call call_, uint512 a_, uint512 b_, uint512 m_) internal view {
        unchecked {
            _moddiv(call_, a_, b_, m_, a_);
        }
    }

    function moddivAssignTo(
        call call_,
        uint512 a_,
        uint512 b_,
        uint512 m_,
        uint512 to_
    ) internal view {
        unchecked {
            _moddiv(call_, a_, b_, m_, to_);
        }
    }

    function _mod(call call_, uint512 a_, uint512 m_, uint512 r_) private view {
        unchecked {
            assembly {
                mstore(call_, 0x40)
                mstore(add(call_, 0x20), 0x20)
                mstore(add(call_, 0x40), 0x40)
                mstore(add(call_, 0x60), mload(a_))
                mstore(add(call_, 0x80), mload(add(a_, 0x20)))
                mstore(add(call_, 0xA0), 0x01)
                mstore(add(call_, 0xC0), mload(m_))
                mstore(add(call_, 0xE0), mload(add(m_, 0x20)))

                pop(staticcall(gas(), 0x5, call_, 0x0100, r_, 0x40))
            }
        }
    }

    function _modexp(call call_, uint512 a_, uint512 e_, uint512 m_, uint512 r_) private view {
        unchecked {
            assembly {
                mstore(call_, 0x40)
                mstore(add(call_, 0x20), 0x40)
                mstore(add(call_, 0x40), 0x40)
                mstore(add(call_, 0x60), mload(a_))
                mstore(add(call_, 0x80), mload(add(a_, 0x20)))
                mstore(add(call_, 0xA0), mload(e_))
                mstore(add(call_, 0xC0), mload(add(e_, 0x20)))
                mstore(add(call_, 0xE0), mload(m_))
                mstore(add(call_, 0x0100), mload(add(m_, 0x20)))

                pop(staticcall(gas(), 0x5, call_, 0x0120, r_, 0x40))
            }
        }
    }

    function _modinv(call call_, uint512 a_, uint512 m_, uint512 r_) private view {
        unchecked {
            uint512 buffer_ = _buffer(call_);

            assembly {
                mstore(buffer_, 0x00)
                mstore(add(buffer_, 0x20), 0x02)
            }

            _sub(m_, buffer_, buffer_);

            assembly {
                mstore(call_, 0x40)
                mstore(add(0x20, call_), 0x40)
                mstore(add(0x40, call_), 0x40)
                mstore(add(0x60, call_), mload(a_))
                mstore(add(0x80, call_), mload(add(a_, 0x20)))
                mstore(add(0xA0, call_), mload(buffer_))
                mstore(add(0xC0, call_), mload(add(buffer_, 0x20)))
                mstore(add(0xE0, call_), mload(m_))
                mstore(add(0x0100, call_), mload(add(m_, 0x20)))

                pop(staticcall(gas(), 0x5, call_, 0x0120, r_, 0x40))
            }
        }
    }

    function _add(uint512 a_, uint512 b_, uint512 r_) private pure {
        unchecked {
            assembly {
                let aWord_ := mload(add(a_, 0x20))
                let sum_ := add(aWord_, mload(add(b_, 0x20)))

                mstore(r_, sum_)

                sum_ := gt(aWord_, sum_)
                sum_ := add(sum_, add(mload(a_), mload(b_)))

                mstore(add(r_, 0x20), sum_)
            }
        }
    }

    function _modadd(call call_, uint512 a_, uint512 b_, uint512 m_, uint512 r_) private view {
        unchecked {
            assembly {
                let aWord_ := mload(add(a_, 0x20))
                let sum_ := add(aWord_, mload(add(b_, 0x20)))

                mstore(add(call_, 0xA0), sum_)

                sum_ := gt(aWord_, sum_)
                sum_ := add(sum_, add(mload(a_), mload(b_)))

                mstore(add(call_, 0x80), sum_)
                mstore(add(call_, 0x60), gt(mload(a_), sum_))

                mstore(call_, 0x60)
                mstore(add(call_, 0x20), 0x20)
                mstore(add(call_, 0x40), 0x40)
                mstore(add(call_, 0xC0), 0x01)
                mstore(add(call_, 0xE0), mload(m_))
                mstore(add(call_, 0x0100), mload(add(m_, 0x20)))

                pop(staticcall(gas(), 0x5, call_, 0x0120, r_, 0x40))
            }
        }
    }

    function _sub(uint512 a_, uint512 b_, uint512 r_) private pure {
        unchecked {
            assembly {
                let aWord_ := mload(add(a_, 0x20))
                let diff_ := sub(aWord_, mload(add(b_, 0x20)))

                mstore(add(r_, 0x20), diff_)

                diff_ := gt(diff_, aWord_)
                diff_ := sub(sub(mload(a_), mload(b_)), diff_)

                mstore(r_, diff_)
            }
        }
    }

    function _modsub(call call_, uint512 a_, uint512 b_, uint512 m_, uint512 r_) private view {
        unchecked {
            int cmp_ = cmp(a_, b_);

            if (cmp_ >= 0) {
                _sub(a_, b_, r_);
            } else {
                _sub(b_, a_, r_);
            }

            assembly {
                mstore(call_, 0x40)
                mstore(add(call_, 0x20), 0x20)
                mstore(add(call_, 0x40), 0x40)
                mstore(add(call_, 0x60), mload(r_))
                mstore(add(call_, 0x80), mload(add(r_, 0x20)))
                mstore(add(call_, 0xA0), 0x01)
                mstore(add(call_, 0xC0), mload(m_))
                mstore(add(call_, 0xE0), mload(add(m_, 0x20)))

                pop(staticcall(gas(), 0x5, call_, 0x0100, r_, 0x40))
            }

            if (cmp_ < 0) {
                _sub(m_, r_, r_);
            }
        }
    }

    function _mul(uint512 a_, uint512 b_, uint512 r_) private pure {
        unchecked {
            assembly {
                let a0_ := shr(128, mload(a_))
                let a1_ := and(mload(a_), 0xffffffffffffffffffffffffffffffff)
                let a2_ := shr(128, mload(add(a_, 0x20)))
                let a3_ := and(mload(add(a_, 0x20)), 0xffffffffffffffffffffffffffffffff)

                let b0_ := shr(128, mload(b_))
                let b1_ := and(mload(b_), 0xffffffffffffffffffffffffffffffff)
                let b2_ := shr(128, mload(add(b_, 0x20)))
                let b3_ := and(mload(add(b_, 0x20)), 0xffffffffffffffffffffffffffffffff)

                // r7
                let current_ := mul(a3_, b3_)
                let ri_ := and(current_, 0xffffffffffffffffffffffffffffffff)

                // r6
                current_ := shr(128, current_)

                let temp_ := mul(a3_, b2_)
                current_ := add(current_, temp_)
                let curry_ := lt(current_, temp_)

                temp_ := mul(a2_, b3_)
                current_ := add(current_, temp_)
                curry_ := add(curry_, lt(current_, temp_))

                mstore(add(r_, 0x20), add(shl(128, current_), ri_))

                // r5
                current_ := add(shl(128, curry_), shr(128, current_))
                curry_ := 0

                temp_ := mul(a3_, b1_)
                current_ := add(current_, temp_)
                curry_ := lt(current_, temp_)

                temp_ := mul(a2_, b2_)
                current_ := add(current_, temp_)
                curry_ := add(curry_, lt(current_, temp_))

                temp_ := mul(a1_, b3_)
                current_ := add(current_, temp_)
                curry_ := add(curry_, lt(current_, temp_))

                ri_ := and(current_, 0xffffffffffffffffffffffffffffffff)

                // r4
                current_ := add(shl(128, curry_), shr(128, current_))
                curry_ := 0

                temp_ := mul(a3_, b0_)
                current_ := add(current_, temp_)
                curry_ := lt(current_, temp_)

                temp_ := mul(a2_, b1_)
                current_ := add(current_, temp_)
                curry_ := add(curry_, lt(current_, temp_))

                temp_ := mul(a1_, b2_)
                current_ := add(current_, temp_)
                curry_ := add(curry_, lt(current_, temp_))

                temp_ := mul(a0_, b2_)
                current_ := add(current_, temp_)
                curry_ := add(curry_, lt(current_, temp_))

                mstore(r_, add(shl(128, current_), ri_))
            }
        }
    }

    function _modmulOverflow(uint512 a_, uint512 b_, call call_) private pure {
        unchecked {
            assembly {
                let a3_ := and(mload(add(a_, 0x20)), 0xffffffffffffffffffffffffffffffff)
                let b3_ := and(mload(add(b_, 0x20)), 0xffffffffffffffffffffffffffffffff)

                let a2_ := shr(128, mload(add(a_, 0x20)))
                let b2_ := shr(128, mload(add(b_, 0x20)))

                let a1_ := and(mload(a_), 0xffffffffffffffffffffffffffffffff)
                let b1_ := and(mload(b_), 0xffffffffffffffffffffffffffffffff)

                let a0_ := shr(128, mload(a_))
                let b0_ := shr(128, mload(b_))

                // r7
                let current_ := mul(a3_, b3_)
                let r0_ := and(current_, 0xffffffffffffffffffffffffffffffff)

                // r6
                current_ := shr(128, current_)

                let temp_ := mul(a2_, b3_)
                current_ := add(current_, temp_)
                let curry_ := lt(current_, temp_)

                temp_ := mul(a3_, b2_)
                current_ := add(current_, temp_)
                curry_ := add(curry_, lt(current_, temp_))

                mstore(add(call_, 0xC0), add(shl(128, current_), r0_))

                // r5
                current_ := add(shl(128, curry_), shr(128, current_))
                curry_ := 0

                temp_ := mul(a1_, b3_)
                current_ := add(current_, temp_)
                curry_ := lt(current_, temp_)

                temp_ := mul(a2_, b2_)
                current_ := add(current_, temp_)
                curry_ := add(curry_, lt(current_, temp_))

                temp_ := mul(a3_, b1_)
                current_ := add(current_, temp_)
                curry_ := add(curry_, lt(current_, temp_))

                r0_ := and(current_, 0xffffffffffffffffffffffffffffffff)

                // r4
                current_ := add(shl(128, curry_), shr(128, current_))
                curry_ := 0

                temp_ := mul(a0_, b3_)
                current_ := add(current_, temp_)
                curry_ := lt(current_, temp_)

                temp_ := mul(a1_, b2_)
                current_ := add(current_, temp_)
                curry_ := add(curry_, lt(current_, temp_))

                temp_ := mul(a2_, b1_)
                current_ := add(current_, temp_)
                curry_ := add(curry_, lt(current_, temp_))

                temp_ := mul(a3_, b0_)
                current_ := add(current_, temp_)
                curry_ := add(curry_, lt(current_, temp_))

                mstore(add(call_, 0xA0), add(shl(128, current_), r0_))

                // r3
                current_ := add(shl(128, curry_), shr(128, current_))
                curry_ := 0

                temp_ := mul(a2_, b0_)
                current_ := add(current_, temp_)
                curry_ := lt(current_, temp_)

                temp_ := mul(a1_, b1_)
                current_ := add(current_, temp_)
                curry_ := add(curry_, lt(current_, temp_))

                temp_ := mul(a0_, b2_)
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

                mstore(add(call_, 0x80), add(shl(128, current_), r0_))

                // r1
                current_ := add(shl(128, curry_), shr(128, current_))
                current_ := add(current_, mul(a0_, b0_))

                mstore(add(call_, 0x60), current_)
            }
        }
    }

    function _modmul2p(call call_, uint512 a_, uint512 b_) private pure {
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
                let c0_ := lt(c1_, prod0_)

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
                c0_ := add(c0_, lt(c1_, prod0_))

                mm_ := mulmod(
                    a0_,
                    b0_,
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                )
                prod1_ := mul(a0_, b0_)
                prod0_ := sub(sub(mm_, prod1_), lt(mm_, prod1_))

                c1_ := add(c1_, prod1_)
                c0_ := add(c0_, lt(c1_, prod1_))
                c0_ := add(c0_, prod0_)

                mstore(add(call_, 0xC0), c3_)
                mstore(add(call_, 0xA0), c2_)
                mstore(add(call_, 0x80), c1_)
                mstore(add(call_, 0x60), c0_)
            }
        }
    }

    function _modmul(call call_, uint512 a_, uint512 b_, uint512 m_, uint512 r_) private view {
        unchecked {
            _modmul2p(call_, a_, b_);

            assembly {
                mstore(call_, 0x80)
                mstore(add(call_, 0x20), 0x20)
                mstore(add(call_, 0x40), 0x40)
                mstore(add(call_, 0xE0), 0x01)
                mstore(add(call_, 0x0100), mload(m_))
                mstore(add(call_, 0x0120), mload(add(m_, 0x20)))

                pop(staticcall(gas(), 0x5, call_, 0x0140, r_, 0x40))
            }
        }
    }

    function _moddiv(call call_, uint512 a_, uint512 b_, uint512 m_, uint512 r_) internal view {
        unchecked {
            uint512 buffer_ = _buffer(call_);

            _modinv(call_, b_, m_, buffer_);
            _modmul2p(call_, a_, buffer_);

            assembly {
                mstore(call_, 0x80)
                mstore(add(0x20, call_), 0x20)
                mstore(add(0x40, call_), 0x40)
                mstore(add(0xE0, call_), 0x01)
                mstore(add(0x0100, call_), mload(m_))
                mstore(add(0x0120, call_), mload(add(m_, 0x20)))

                pop(staticcall(gas(), 0x5, call_, 0x0140, r_, 0x40))
            }
        }
    }

    function _buffer(call call_) private pure returns (uint512 buffer_) {
        unchecked {
            assembly {
                buffer_ := add(call_, 0x0140)
            }
        }
    }

    function _allocate(uint256 bytes_) private pure returns (uint256 handler_) {
        unchecked {
            assembly {
                handler_ := mload(0x40)
                mstore(0x40, add(handler_, bytes_))
            }
        }
    }
}
