// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct AddressSet {
    address[] addrs;
    mapping(address => bool) saved;
}

address constant STARTER_ADDRESS = address(0xc0ffee);

library AddressSets {
    /// @notice picks a random address from the set
    /// @param s the address set
    /// @param seed seed to pick random index
    /// @return the address
    function rand(AddressSet storage s, uint256 seed) internal view returns (address) {
        if (s.addrs.length > 0) {
            return s.addrs[seed % s.addrs.length];
        } else {
            return STARTER_ADDRESS;
        }
    }

    /// @notice adds a new address to the set
    /// @param s the address set
    /// @param addr address to check
    function add(AddressSet storage s, address addr) internal {
        if (!s.saved[addr]) {
            s.addrs.push(addr);
            s.saved[addr] = true;
        }
    }

    /// @notice returns whether address is part of the set
    /// @param s the address set
    /// @param addr address to check
    /// @return true if the address is part of the set, false otherwise
    function contains(AddressSet storage s, address addr) internal view returns (bool) {
        return s.saved[addr];
    }

    /// @notice returns the number of addresses in the set
    /// @param s the address set
    /// @return the number of addresses in the set
    function count(AddressSet storage s) internal view returns (uint256) {
        return s.addrs.length;
    }

    /// @notice returns the address at the given index
    /// @dev index must be less than the number of addresses in the set
    /// @param s the address set
    /// @param index the index of the address to return
    /// @return the address at the given index
    function getAddressAtIndex(AddressSet storage s, uint256 index) public view returns (address) {
        return s.addrs[index];
    }
}
