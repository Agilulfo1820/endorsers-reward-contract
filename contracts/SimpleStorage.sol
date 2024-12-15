// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title SimpleStorage - A simple contract to demonstrate setting and getting a value
contract SimpleStorage {
    // State variable to store a value
    uint256 private storedValue;

    /// @notice Sets a new value
    /// @param _value The value to store
    function setValue(uint256 _value) public {
        storedValue = _value;
    }

    /// @notice Retrieves the stored value
    /// @return The stored value
    function getValue() public view returns (uint256) {
        return storedValue;
    }
}
