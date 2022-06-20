// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @dev This library tries to reduce the cost of calling the Paginator library.
 * On average, it will cost 311 gas less to read one array element.
 */
library PaginatorLite {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /**
     * @dev {inpMemArrSlot} should be the end of the currently allocated memory.
     * {mload(0x40)} contains "free memory pointer" and equal {0x80}
     *
     * {retMemArrEndSlot} should be less then {retMemArrStartSlot}, because arr can have any length
     *
     * {inpMemArrSlot}      - memory slot contain storage slot value on {arr}/{set}
     * {retMemArrEndSlot}   - memory slot contain bits length of new array
     * {retMemArrStartSlot} - memory slot contain start bit position for new array
     */
    uint256 public constant inpMemArrSlot = 0x80; // 128 bit
    uint256 public constant retMemArrEndSlot = 0xA0; // 160 bit
    uint256 public constant retMemArrStartSlot = 0xC0; // 192 bit

    function part(
        uint256[] storage arr,
        uint256 offset,
        uint256 limit
    ) internal view returns (uint256[] memory) {
        assembly {
            mstore(inpMemArrSlot, arr.slot)
        }
        _loadNewArrayToMemory(offset, limit);

        assembly {
            return(retMemArrStartSlot, mload(retMemArrEndSlot))
        }
    }

    function part(
        address[] storage arr,
        uint256 offset,
        uint256 limit
    ) internal view returns (address[] memory) {
        assembly {
            mstore(inpMemArrSlot, arr.slot)
        }
        _loadNewArrayToMemory(offset, limit);

        assembly {
            return(retMemArrStartSlot, mload(retMemArrEndSlot))
        }
    }

    function part(
        bytes32[] storage arr,
        uint256 offset,
        uint256 limit
    ) internal view returns (bytes32[] memory) {
        assembly {
            mstore(inpMemArrSlot, arr.slot)
        }
        _loadNewArrayToMemory(offset, limit);

        assembly {
            return(retMemArrStartSlot, mload(retMemArrEndSlot))
        }
    }

    function part(
        EnumerableSet.UintSet storage set,
        uint256 offset,
        uint256 limit
    ) internal view returns (uint256[] memory) {
        assembly {
            mstore(inpMemArrSlot, set.slot)
        }
        _loadNewArrayToMemory(offset, limit);

        assembly {
            return(retMemArrStartSlot, mload(retMemArrEndSlot))
        }
    }

    function part(
        EnumerableSet.AddressSet storage set,
        uint256 offset,
        uint256 limit
    ) internal view returns (address[] memory) {
        assembly {
            mstore(inpMemArrSlot, set.slot)
        }
        _loadNewArrayToMemory(offset, limit);

        assembly {
            return(retMemArrStartSlot, mload(retMemArrEndSlot))
        }
    }

    function part(
        EnumerableSet.Bytes32Set storage set,
        uint256 offset,
        uint256 limit
    ) internal view returns (bytes32[] memory) {
        assembly {
            mstore(inpMemArrSlot, set.slot)
        }
        _loadNewArrayToMemory(offset, limit);

        assembly {
            return(retMemArrStartSlot, mload(retMemArrEndSlot))
        }
    }

    function _loadNewArrayToMemory(uint256 offset, uint256 limit) private view {
        assembly {
            // START DEFINE LAST INDEX
            let baseLength := sload(mload(inpMemArrSlot))
            let to := add(offset, limit) // 6

            if gt(to, baseLength) {
                to := baseLength
            } // to = 5
            if gt(offset, to) {
                to := offset
            }
            // END

            // START CREATE NEW ARRAY
            // Get new array length
            let newLength := sub(to, offset)

            // Write new array to this point
            mstore(retMemArrStartSlot, 0x20) // startArrSlot => #160
            // Write new array length
            mstore(add(retMemArrStartSlot, 0x20), newLength)
            // Write each storage value to new memory slot, then read in main function
            for {
                let i
            } lt(i, newLength) {
                i := add(i, 1)
            } {
                mstore(
                    add(retMemArrStartSlot, add(0x40, mul(i, 0x20))),
                    sload(add(keccak256(inpMemArrSlot, 0x20), add(offset, i)))
                )
            }

            // Write array length in bits to {retMemArrEndSlot}, then read in main function
            mstore(retMemArrEndSlot, add(mul(newLength, 0x20), 0x40))
            // END
        }
    }
}
