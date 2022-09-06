// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract USDT is ERC20, Ownable {
    constructor() ERC20("USDT", "USDT") {
        mint(_msgSender(),1000000000000000000000000000000000 * 10**decimals());
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}