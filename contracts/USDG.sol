// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IConfig.sol";
import "./interfaces/IStableVault.sol";

//0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526

contract USDG is ERC20, Ownable {

    address private config;
    address private vault;


    constructor(address _config , address _vault) ERC20("USDG", "USDG") {
        setConfig(_config);
        setStableVault(_vault);
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function setConfig(address _config) public onlyOwner{
        require(_config != address(0));
        config = _config;
    }

    function setStableVault(address _vault) public onlyOwner{
        require(_vault != address(0));
        vault = _vault;
    }


    function Amount_Convo(address _token , uint256 amount) public view returns (uint256 _amount) { 
        if(decimals() >  IERC20Metadata(_token).decimals()){
        _amount = ((amount) ) * (10**( decimals() - IERC20Metadata(_token).decimals() ));
        }
        else if ( IERC20Metadata(_token).decimals() > decimals() ){
        _amount = amount  / (10**(IERC20Metadata(_token).decimals() - decimals()));
        }
        else {
        _amount = amount;
        }
    }
  

    //uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

    function mint(address _token , address to ,uint256 amount) public payable{

        require(IStableVault(vault).enabled(_token), "Token not supported");

        IERC20(_token).transferFrom(to, address(this) , amount);
        uint256 tomint = Amount_Convo(_token , amount);

        require(tomint > 0 ,"Cannot mint value to low");

        // _mint(to, tomint/100 * (100 - IConfig(config).minting_fee()));
        // _mint(IConfig(config).platform() , (tomint/100) * IConfig(config).minting_fee());

        uint256 _deductamount = (tomint * IConfig(config).minting_fee()) / IConfig(config).feeDenominator();
        
        _mint(to, tomint - _deductamount );
        _mint(IConfig(config).platform() , _deductamount );

    }

    function burn(address _token , uint256 amount) public virtual {
         require(IStableVault(vault).enabled(_token), "Token not supported");
         uint256 toBurn = Amount_Convo(_token , amount);

         _burn(_msgSender(), toBurn);

         uint256 _deductamount = (amount * IConfig(config).burning_fee()) / IConfig(config).feeDenominator();


         IERC20(_token).transfer(_msgSender() , amount - _deductamount);
    }
 
    function burnFrom(address _token , address account, uint256 amount) public virtual {
         require(IStableVault(vault).enabled(_token), "Token not supported");

         uint256 toBurn = Amount_Convo(_token , amount);

        _spendAllowance(account, _msgSender(), toBurn);
        _burn(account, toBurn);

         uint256 _deductamount = (amount * IConfig(config).burning_fee()) / IConfig(config).feeDenominator();

        IERC20(_token).transfer(account ,amount - _deductamount);
    }
}