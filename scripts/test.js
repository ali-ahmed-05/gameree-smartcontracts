// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
const fs = require("fs");
const fse = require('fs-extra');
const { config } = require("dotenv");

async function main() {

    const [deployer,per1,per2] = await ethers.getSigners();

    console.log("Account balance:", (await deployer.getBalance()).toString());

    Config = await ethers.getContractFactory("Config")
    _config =await Config.deploy()
    await _config.deployed()

    USDG = await ethers.getContractFactory("USDG")
    uSDG =await USDG.deploy('0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526')
    await uSDG.deployed()

    
    marketplace = await ethers.getContractFactory("marketplace")
    market =await marketplace.deploy(_config.address)
    await market.deployed()
    
    
    
    let set_config = await uSDG.setConfig(_config.address)
    await set_config.wait()

   

    

    let set_fee = await _config.setNFTFee(3)
    await set_fee.wait()


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

    let deposit = await uSDG.mint({value : hre.ethers.utils.parseUnits('0.006',8)})
    await deposit.wait()
    
    let approve = await uSDG.approve(gameRee.address , '100000000000000000000000000')
    await approve.wait()

    let mint = await gameRee.mintNonFungible(token_Type , addresses, [])
    await mint.wait()

    let approveForAll = await gameRee.setApprovalForAllWithData(market.address , true)
    await approveForAll.wait()

    let create = await market.createMarketItem(gameRee.address,
        '57896044618658097711785492504343953927315557066662158946655541218820101242881',
        '100000000000000',
        0)
    await create.wait()

    approve = await uSDG.approve(market.address , '100000000000000000000000000')
    await approve.wait()

    let sale = await market.createMarketSale(
        gameRee.address,
        1
        )

    await sale.wait()

    console.log("gameRee deployed to:", gameRee.address );
   // saveFrontendFiles(gameRee , uSDG ,market ,_config)
}

function saveFrontendFiles(nFT , uSDG , market ,_config) {
  
  const contractsDir = "../Gameree-Frontend/src/contract";

  if (!fs.existsSync(contractsDir)) {
    fs.mkdirSync(contractsDir);
  }

let config = `
 export const NFT_addr = "${nFT.address}"
 export const gBPG_addr = "${uSDG.address}"
 export const config_addr = "${_config.address}"
 export const market_addr = "${market.address}"
`

   let data = JSON.stringify(config)
    fs.writeFileSync(
    contractsDir + '/addresses.js', JSON.parse(data)

  );
 

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
