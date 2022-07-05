//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract MockTarget {
    uint256 public _state;
    address public _caller;

    function state() public view returns (uint256, address) {
        return (_state, _caller);
    }

    function targetFunction(uint256 number) external returns (bool) {
        _state += number;
        _caller = msg.sender;
        return true;
    }
}
