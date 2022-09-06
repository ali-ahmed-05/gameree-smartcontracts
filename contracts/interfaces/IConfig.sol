// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IConfig {
   
    function platform() external view returns (address payable);
    function nft_fee() external view returns (uint256);
    function minting_fee() external view returns (uint256);
    function burning_fee() external view returns (uint256);
    function USDG() external view returns (address);
    function feeDenominator() external view returns (uint256);

}