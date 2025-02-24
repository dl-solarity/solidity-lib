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

    struct IStorage {
        mapping(bytes32 => InitializableStorage) initializableStorage;
    }

    struct InitializableStorage {
        uint64 initialized;
        bool initializing;
    }

    event Initialized(bytes32 storageSlot, uint64 version);

    error AlreadyInitialized();
    error InvalidInitialization();
    error NotInitializing();

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most
     * once for a particular storage in a Diamond proxy that begins with {storageSlot_}.
     * In its scope, `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer(bytes32 storageSlot_) {
        if (_getInitializedVersion(storageSlot_) != 0) revert AlreadyInitialized();

        _setInitializing(storageSlot_, true);
        _;
        _setInitializing(storageSlot_, false);

        _setInitialized(storageSlot_, 1);

        emit Initialized(storageSlot_, 1);
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
    modifier reinitializer(bytes32 storageSlot_, uint64 version_) {
        if (_isInitializing(storageSlot_) || _getInitializedVersion(storageSlot_) >= version_) {
            revert InvalidInitialization();
        }

        _setInitialized(storageSlot_, version_);

        _setInitializing(storageSlot_, true);
        _;
        _setInitializing(storageSlot_, false);

        emit Initialized(storageSlot_, version_);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing(bytes32 storageSlot_) {
        if (!_isInitializing(storageSlot_)) revert NotInitializing();
        _;
    }

    function _getInitializableStorage() internal pure returns (IStorage storage _iss) {
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
    function _disableInitializers(bytes32 storageSlot_) internal virtual {
        if (_isInitializing(storageSlot_)) revert InvalidInitialization();

        if (_getInitializedVersion(storageSlot_) != type(uint64).max) {
            _setInitialized(storageSlot_, type(uint64).max);

            emit Initialized(storageSlot_, type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized for the provided storage slot.
     */
    function _getInitializedVersion(bytes32 storageSlot_) internal view returns (uint64) {
        return _getInitializableStorage().initializableStorage[storageSlot_].initialized;
    }

    /**
     * @dev Returns 1 if the storage at the specified slot is currently initializing, 0 otherwise.
     */
    function _isInitializing(bytes32 storageSlot_) internal view returns (bool) {
        return _getInitializableStorage().initializableStorage[storageSlot_].initializing;
    }

    /**
     * @dev Internal function that sets the initialization version for the provided storage slot.
     */
    function _setInitialized(bytes32 storageSlot_, uint64 value_) private {
        _getInitializableStorage().initializableStorage[storageSlot_].initialized = value_;
    }

    /**
     * @dev Internal function that sets the initializing value for the provided storage slot.
     */
    function _setInitializing(bytes32 storageSlot_, bool value_) private {
        _getInitializableStorage().initializableStorage[storageSlot_].initializing = value_;
    }
}
