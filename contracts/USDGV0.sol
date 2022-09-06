// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.4;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// import "./interfaces/IConfig.sol";

// //0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526

// contract USDG is ERC20, Ownable {

//     AggregatorV3Interface internal priceFeed;

//     address private config;

//     uint256 CHAIN_DECIMALS = 1 * 10 **8 ;
//     uint256 CHAIN_DENOMINATOR = (10**(18-8));

//     constructor(address aggregator) ERC20("USDG", "USDG") {
//         setAggregator(aggregator);
//     }

//     function decimals() public view virtual override returns (uint8) {
//         return 18;
//     }

//     function setAggregator(address aggregator) public onlyOwner{
//         require(aggregator != address(0));
//         priceFeed = AggregatorV3Interface(aggregator);
//     }

//     function setConfig(address _config) public onlyOwner{
//         require(_config != address(0));
//         config = _config;
//     }

//     function getLatestPrice() public view returns (int) {
//         (
//             /*uint80 roundID*/,
//             int price,
//             /*uint startedAt*/,
//             /*uint timeStamp*/,
//             /*uint80 answeredInRound*/
//         ) = priceFeed.latestRoundData();
//         return price;
//     }

//     function mintAmount(uint256 amountBNB) public view returns (uint256 amount) { 
//         amount = ((amountBNB * uint256(getLatestPrice())) / CHAIN_DECIMALS ) * CHAIN_DENOMINATOR;
//     }

//     function getPrice(uint256 amount) public view returns(uint256 price){    
//         price = (amount * CHAIN_DECIMALS) / uint256(getLatestPrice());
//         price = price  / CHAIN_DENOMINATOR;
//     }

//     function mint(address to) public payable{
//         require(mintAmount(msg.value) > 0 ,"Cannot mint value to low");
//         _mint(to, mintAmount((msg.value/100)*(100 - IConfig(config).minting_fee())));
//         _mint(to, mintAmount(msg.value/100) * IConfig(config).minting_fee());
//     }

//     function burn(uint256 amount) public payable virtual {
//          payable(_msgSender()).transfer(getPrice(amount));
//         _burn(_msgSender(), amount);
//     }
 
//     function burnFrom(address account, uint256 amount) public payable virtual {
//          payable(account).transfer(getPrice(amount));
//         _spendAllowance(account, _msgSender(), amount);
//         _burn(account, amount);
//     }
// }