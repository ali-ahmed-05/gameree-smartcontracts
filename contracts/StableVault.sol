// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IStableVault.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";



contract StableVault is IStableVault , Ownable {

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private mySet;

    mapping(address => bool) private _enabled;

    function enabled(address _token) external view returns(bool){
        //return _enabled[_token];

        return mySet.contains(_token);
    }

    function enableToken(address _token) public onlyOwner {
        require(_token != address(0),"null address");
        // _enabled[_token] = true;

        require(mySet.contains(_token) == false ,"null address");
        mySet.add(_token);
    }

    function DisableToken(address _token) public onlyOwner {
        // require(_enabled[_token] == true,"Token dosent exist");
        //  _enabled[_token] = false; 

        require(mySet.contains(_token) ,"null address");
        mySet.remove(_token);
         
    }

    function length() external view returns(uint256){
        return mySet.length();
    }

    function at(uint256 index) external view returns(address){
        return mySet.at(index);
    }

}