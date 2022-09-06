//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./interfaces/IConfig.sol";


contract Config is IConfig, Ownable  {

    address payable private _platform;
    address private _USDG;
    uint256 private NFT_FEE = 3;
    uint256 private TOKEN_MINTING_FEE = 50;
    uint256 private TOKEN_BURNING_FEE = 50;
    uint256 private FEE_DENOMINATOR = 10000;

    function platform() public override view returns (address payable) {
        return _platform;
    }

    function nft_fee() public override view returns (uint256) {
        return NFT_FEE;
    }

    function minting_fee() public override view returns (uint256) {
        return TOKEN_MINTING_FEE;
    }

    function burning_fee() public override view returns (uint256) {
        return TOKEN_BURNING_FEE;
    }

    function USDG() public override view returns (address) {
        return _USDG;
    }

    function feeDenominator() public override view returns (uint256) {
        return FEE_DENOMINATOR;
    }

    function setPlatform(address payable platform_) public onlyOwner {
        require(platform_ != address(0),"setting 0 address");
        _platform = platform_;
    }

    
    function setNFTFee(uint256 fee_) public onlyOwner {
        require(fee_ <= FEE_DENOMINATOR && fee_ >=0,"setting fee out of bound");
        NFT_FEE = fee_;
    }

    function setMintingFee(uint256 fee_) public onlyOwner {
        require(fee_ <= FEE_DENOMINATOR && fee_ >=0,"setting fee out of bound");
        TOKEN_MINTING_FEE = fee_;
    }

    function setUSDGaddress(address _token) public onlyOwner {
        require(_token != address(0),"setting 0 address");
        _USDG = _token;
    }
}