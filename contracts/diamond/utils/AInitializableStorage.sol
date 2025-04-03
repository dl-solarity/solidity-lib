// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @notice The Diamond standard module
 *
 * This is a modified version of the OpenZeppelin Initializable contract to be compatible
 * with the Diamond Standard.
 */
abstract contract AInitializableStorage {
    bytes32 internal constant INITIALIZABLE_STORAGE_SLOT =
        keccak256("diamond.standard.initializable.storage");

    struct IDiamondInitializableStorage {
        mapping(bytes32 => DiamondInitializableStorage) initializableStorage;
    }

    struct DiamondInitializableStorage {
        uint64 initialized;
        bool initializing;
    }

    event DiamondInitialized(bytes32 storageSlot, uint64 version);

    error DiamondAlreadyInitialized();
    error DiamondInvalidInitialization();
    error DiamondNotInitializing();

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most
     * once for a particular storage in a Diamond proxy that begins with {storageSlot_}.
     * In its scope, `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Emits an {Initialized} event.
     */
    modifier diamondInitializer(bytes32 storageSlot_) {
        if (_getDiamondInitializedVersion(storageSlot_) != 0) revert DiamondAlreadyInitialized();

        _setInitializing(storageSlot_, true);
        _;
        _setInitializing(storageSlot_, false);

        _setInitialized(storageSlot_, 1);

        emit DiamondInitialized(storageSlot_, 1);
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once
     * for a particular storage in a Diamond proxy that begins with {storageSlot_},
     * and only if the storage hasn't been initialized to a greater version before.
     * In its scope, `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a storage slot, executing them in the right order is up to the developer or operator.
     *
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier diamondReinitializer(bytes32 storageSlot_, uint64 version_) {
        if (
            _isDiamondInitializing(storageSlot_) ||
            _getDiamondInitializedVersion(storageSlot_) >= version_
        ) {
            revert DiamondInvalidInitialization();
        }

        _setInitialized(storageSlot_, version_);

        _setInitializing(storageSlot_, true);
        _;
        _setInitializing(storageSlot_, false);

        emit DiamondInitialized(storageSlot_, version_);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyDiamondInitializing(bytes32 storageSlot_) {
        if (!_isDiamondInitializing(storageSlot_)) revert DiamondNotInitializing();
        _;
    }

    function _getDiamondInitializableStorage()
        internal
        pure
        returns (IDiamondInitializableStorage storage _iss)
    {
        bytes32 slot_ = INITIALIZABLE_STORAGE_SLOT;

        assembly {
            _iss.slot := slot_
        }
    }

    /**
     * @dev Locks the contract.
     * It is recommended to use this to lock Diamond Facets contracts.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableDiamondInitializers(bytes32 storageSlot_) internal virtual {
        if (_isDiamondInitializing(storageSlot_)) revert DiamondInvalidInitialization();

        if (_getDiamondInitializedVersion(storageSlot_) != type(uint64).max) {
            _setInitialized(storageSlot_, type(uint64).max);

            emit DiamondInitialized(storageSlot_, type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized for the provided storage slot.
     */
    function _getDiamondInitializedVersion(bytes32 storageSlot_) internal view returns (uint64) {
        return _getDiamondInitializableStorage().initializableStorage[storageSlot_].initialized;
    }

    /**
     * @dev Returns 1 if the storage at the specified slot is currently initializing, 0 otherwise.
     */
    function _isDiamondInitializing(bytes32 storageSlot_) internal view returns (bool) {
        return _getDiamondInitializableStorage().initializableStorage[storageSlot_].initializing;
    }

    /**
     * @dev Internal function that sets the initialization version for the provided storage slot.
     */
    function _setInitialized(bytes32 storageSlot_, uint64 value_) private {
        _getDiamondInitializableStorage().initializableStorage[storageSlot_].initialized = value_;
    }

    /**
     * @dev Internal function that sets the initializing value for the provided storage slot.
     */
    function _setInitializing(bytes32 storageSlot_, bool value_) private {
        _getDiamondInitializableStorage().initializableStorage[storageSlot_].initializing = value_;
    }
}
