// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./interfaces/ICompoundRateKeeperV2.sol";

contract CompoundRateKeeperV2 is ICompoundRateKeeperV2, Ownable {
    using Math for uint256;

    uint256 public currentRate;
    uint256 public annualPercent;

    uint64 public capitalizationPeriod;
    uint64 public lastUpdate;

    bool public hasMaxRateReached;

    constructor(uint256 _annualPercent) {
        require(_annualPercent >= _getDecimals(), "CRK: annual percent can't be less then 1");

        capitalizationPeriod = 31536000;
        lastUpdate = uint64(block.timestamp);

        annualPercent = _annualPercent;
        currentRate = _getDecimals();
    }

    function setAnnualPercent(uint256 _annualPercent) external override onlyOwner {
        require(!hasMaxRateReached, "CRK: max rate has been reached");
        require(_annualPercent >= _getDecimals(), "CRK: annual percent can't be less then 1");

        currentRate = getCompoundRate();
        annualPercent = _annualPercent;

        lastUpdate = uint64(block.timestamp);

        emit AnnualPercentChanged(_annualPercent);
    }

    function setCapitalizationPeriod(uint32 _capitalizationPeriod) external override onlyOwner {
        require(!hasMaxRateReached, "CRK: max rate has been reached");
        require(_capitalizationPeriod > 0, "CRK: invalid value");

        currentRate = getCompoundRate();
        capitalizationPeriod = _capitalizationPeriod;

        lastUpdate = uint64(block.timestamp);

        emit CapitalizationPeriodChanged(_capitalizationPeriod);
    }

    /// @dev Call this function only when getCompoundRate() or getPotentialCompoundRate()
    function emergencyUpdateCompoundRate() external override {
        try this.getCompoundRate() returns (uint256 _rate) {
            if (_rate == __getMaxRate()) hasMaxRateReached = true;
        } catch {
            hasMaxRateReached = true;
        }
    }

    /// @dev @notice Calculate compound rate for this moment.
    function getCompoundRate() public view override returns (uint256) {
        return __getPotentialCompoundRate(uint64(block.timestamp));
    }

    /**
     * @dev Calculate compound rate at a particular time.
     *
     * Main contract logic, calculate actual compound rate.
     * If rate bigger than __getMaxRate(), return __getMaxRate().
     * If function is reverted by overflow, call emergencyUpdateCompoundRate()
     */
    function getPotentialCompoundRate(uint64 _timestamp) public view override returns (uint256) {
        return __getPotentialCompoundRate(_timestamp);
    }

    function _getDecimals() internal pure returns (uint256) {
        return 10**27;
    }

    /// @dev Max accessible compound rate.
    function __getMaxRate() private pure returns (uint256) {
        return type(uint128).max * _getDecimals();
    }

    function __getPotentialCompoundRate(uint64 _timestamp) private view returns (uint256) {
        if (hasMaxRateReached) return __getMaxRate();

        uint64 _lastUpdate = lastUpdate;

        // Require is made to avoid incorrect calculations at the front
        require(_lastUpdate <= _timestamp, "CRK: invalid timestamp");

        if (_timestamp == _lastUpdate) return currentRate;

        uint64 _secondsPassed = _timestamp - _lastUpdate;

        uint64 _capitalizationPeriod = capitalizationPeriod;
        uint64 _capitalizationPeriodsNum = _secondsPassed / _capitalizationPeriod;
        uint64 _secondsLeft = _secondsPassed % _capitalizationPeriod;

        uint256 _annualPercent = annualPercent;
        uint256 _rate = currentRate;

        if (_capitalizationPeriodsNum != 0) {
            uint256 _capitalizationPeriodRate = __pow(
                _annualPercent,
                _capitalizationPeriodsNum,
                _getDecimals()
            );
            _rate = (_rate * _capitalizationPeriodRate) / _getDecimals();
        }

        if (_secondsLeft > 0) {
            uint256 _rateLeft = _getDecimals() +
                ((_annualPercent - _getDecimals()) * _secondsLeft) /
                _capitalizationPeriod;
            _rate = (_rate * _rateLeft) / _getDecimals();
        }

        return _rate.min(__getMaxRate());
    }

    /// @dev github.com/makerdao/dss implementation of exponentiation by squaring.
    function __pow(
        uint256 _num,
        uint256 _exponent,
        uint256 _base
    ) private pure returns (uint256 _res) {
        assembly {
            function power(x, n, b) -> z {
                switch x
                case 0 {
                    switch n
                    case 0 {
                        z := b
                    }
                    default {
                        z := 0
                    }
                }
                default {
                    switch mod(n, 2)
                    case 0 {
                        z := b
                    }
                    default {
                        z := x
                    }

                    let half := div(b, 2)
                    for {
                        n := div(n, 2)
                    } n {
                        n := div(n, 2)
                    } {
                        let xx := mul(x, x)
                        if iszero(eq(div(xx, x), x)) {
                            revert(0, 0)
                        }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) {
                            revert(0, 0)
                        }
                        x := div(xxRound, b)
                        if mod(n, 2) {
                            let zx := mul(z, x)
                            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                                revert(0, 0)
                            }

                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) {
                                revert(0, 0)
                            }

                            z := div(zxRound, b)
                        }
                    }
                }
            }

            _res := power(_num, _exponent, _base)
        }
    }
}
