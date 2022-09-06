// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IStableVault {
    function enabled(address _token) external view returns(bool);
}