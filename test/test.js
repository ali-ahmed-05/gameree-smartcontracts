const { expect } = require("chai");
const { ethers } = require("hardhat");

async function mineNBlocks(n) {
  for (let index = 0; index < n; index++) {
    await ethers.provider.send('evm_mine');
  }
}

const timeLatest = async () => {
  const block = await hre.ethers.provider.getBlock('latest');
  return ethers.BigNumber.from(block.timestamp);
};

const setBlocktime = async (time) => {
  await hre.ethers.provider.send('evm_setNextBlockTimestamp', [time]);
  await hre.ethers.provider.send("evm_mine")
};

describe("Game Ree",  function ()  {

  
  let GameRee1155
  let gameRee
  let USDG
  let uSDG
  let marketplace
  let market
  let Config
  let _config
  let StableVault
  let _StableVault
  let USDT
  let usdt

  



//   let [_,per1,per2,per3] = [1,1,1,1]

  it("Should deploy all smart contracts", async function () {

    [_,per1,per2,per3] = await ethers.getSigners()

    StableVault = await ethers.getContractFactory("StableVault")
    _StableVault =await StableVault.deploy()
    await _StableVault.deployed()


    Config = await ethers.getContractFactory("Config")
    _config =await Config.deploy()
    await _config.deployed()

    USDT = await ethers.getContractFactory("USDT")
    usdt =await USDT.deploy()
    await usdt.deployed()

    await _StableVault.enableToken(usdt.address)

    console.log("ENABLE",(await _StableVault.enabled(_.address)))
    console.log("ENABLE",(await _StableVault.at(0)).toString())


    USDG = await ethers.getContractFactory("USDG")
    uSDG =await USDG.deploy(_config.address , _StableVault.address)
    await uSDG.deployed()

    
    marketplace = await ethers.getContractFactory("marketplace")
    market =await marketplace.deploy(_config.address)
    await market.deployed()
    
    
    
    let set_config = await uSDG.setConfig(_config.address)
    await set_config.wait()

    await _config.setUSDGaddress(uSDG.address)

    await _config.setPlatform(per2.address)


    let set_fee = await _config.setNFTFee(3)
    await set_fee.wait()

    let decimals = await usdt.decimals()
    decimals = decimals.toString()
    console.log("DECIMALS" , decimals)
    let value = '11'

    let allowance = await usdt.approve(uSDG.address , ethers.utils.parseUnits(value,decimals))
    

    let mintToken = await uSDG.mint(usdt.address , _.address , ethers.utils.parseUnits(value,decimals))
    await mintToken.wait()

    let balance = await uSDG.balanceOf(_.address)
    


    console.log(balance.toString())

    balance = await usdt.balanceOf(_.address)
    console.log("USDT",balance.toString())

    value = '0.5'

    let Burn = await  uSDG.burn(usdt.address,ethers.utils.parseUnits(value,decimals))

    balance = await uSDG.balanceOf(_.address)
    console.log(balance.toString())

    balance = await usdt.balanceOf(_.address)
    console.log("USDT",balance.toString())

    allowance = await uSDG.approve(_.address , ethers.utils.parseUnits(value,18))

    let burnFrom = await uSDG.burnFrom(usdt.address,_.address,ethers.utils.parseUnits(value,decimals))

    balance = await uSDG.balanceOf(_.address)
    console.log(balance.toString())

    let transfer = await uSDG.transfer(per1.address ,ethers.utils.parseUnits('1',18))
   


    let addresses = ["0x27515B6d63637A9Cf906414B7eC44fE3DA576152","0xa337275a57f9ad3cB17a761559c29fF990A7bf1F","0x29e5AE7C1c3D3ce86cA42EA7598fe56cC30d9C93"]

    GameRee1155 = await ethers.getContractFactory("GameRee1155")
    gameRee =await GameRee1155.deploy("https://gateway.pinata.cloud/ipfs/QmXvzCzSRmYQdNdAQx2wgmwBiay7Z8iY4ahPiEFwbZbyrg/" ,uSDG.address , '50000000000000000' )
    await gameRee.deployed()
    
    let tx = await gameRee.create(false);
    await tx.wait()

    let token_Type = '57896044618658097711785492504343953927315557066662158946655541218820101242880'

     tx = await gameRee._setNonFungibleURI(token_Type,1,"https://gateway.pinata.cloud/ipfs/QmXvzCzSRmYQdNdAQx2wgmwBiay7Z8iY4ahPiEFwbZbyrg/MetaData1.json")
    await tx.wait()
     tx =await gameRee._setNonFungibleURI(token_Type,2,"https://gateway.pinata.cloud/ipfs/QmXvzCzSRmYQdNdAQx2wgmwBiay7Z8iY4ahPiEFwbZbyrg/MetaData2.json")
    await tx.wait()
     tx =await gameRee._setNonFungibleURI(token_Type,3,"https://gateway.pinata.cloud/ipfs/QmXvzCzSRmYQdNdAQx2wgmwBiay7Z8iY4ahPiEFwbZbyrg/MetaData3.json")
     await tx.wait()
    console.log("owner", await gameRee.uri(1))

    


    // //let dep  = await gBPG.connect(per1).mint(per1.address,{value:'10000000'})
    // let mint =await gameRee.connect(per1).mintNonFungibleWithURI(token_Type,addresses, [],"asdasdasd")
    
    // await mint.wait()

    let approve = await gameRee.setApprovalForAll(market.address , true)
    let createSale = await market.createMarketItem(
      gameRee.address,
      "57896044618658097711785492504343953927315557066662158946655541218820101242881",
      11111,
      0
      );

    await createSale.wait()

    let exits = await market.exists("57896044618658097711785492504343953927315557066662158946655541218820101242881", gameRee.address)
    console.log(exits)

    allowance = await uSDG.connect(per1).approve(market.address , 11111)

    let sale = await market.connect(per1).createMarketSale(
    gameRee.address,
    1
    );


  
  //   console.log("wait",await mint.wait())
  //   console.log(await gameRee._lastTokenId())
  //   console.log((await gameRee.uri(1)).toString())
  //   // console.log((await gameRee.ownerOf(1)).toString())
  //   // console.log((await gameRee.ownerOf(2)).toString())
  //   // console.log((await gameRee.ownerOf(3)).toString())
   
  //  token_Type = '57896044618658097711785492504343953927315557066662158946655541218820101242881'
  // //console.log( (await gameRee.ownerOf(token_Type)).toString())
  //   console.log( (await gameRee.ownerOf(token_Type)).toString())

  //   let trans  = await gameRee.safeTransferFrom(_.address,addresses[2],token_Type,1,[])
  //   await trans.wait()
  //   trans  = await gameRee.safeTransferFrom(addresses[2],_.address,token_Type,1,[])
  //   await trans.wait()
  //   console.log( (await gameRee.balanceOf(addresses[2], token_Type)).toString())

  //    console.log( (await gameRee.uri(await gameRee._lastTokenId())).toString())

    


   
  });
 


});