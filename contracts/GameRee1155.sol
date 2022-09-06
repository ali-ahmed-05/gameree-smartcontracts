// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BEP1155.sol";
import "./BEP1155Burnable.sol";
import "./Ownable.sol";
import "./library/SafeMath.sol";
import "./interfaces/IBEP1155Mixed.sol";
import "./Ownable.sol";
import "./BEP1155Burnable.sol";
import "./interfaces/IBEP20.sol";
import "hardhat/console.sol";


contract GameRee1155 is Context, BEP1155, IBEP1155Mixed, BEP1155Burnable, Ownable {

     /** GBPG : fungible token , GRE : NFT */

    string private _name;
    string private _symbol;
    uint256 private _decimal;

    string private _fungibleTokenName;
    string private _nonFungibleTokenName;

    address token;
    uint256 minting_price;

    /**
     * Use a split bit implementation:
     *  - Bit 255: type flag (0 = fungible, 1 = non-fungible)
     *  - Bits 255-128: type id
     *  - Bits 127-0: token index (non-fungible only)
     */

    uint256 constant TYPE_MASK = type(uint128).max << 128;
    uint256 constant NF_INDEX_MASK = type(uint128).max;
    uint256 constant TYPE_NF_BIT = 1 << 255;

    uint256 nonce;

    mapping (uint256 => address) public creators;
    mapping (uint256 => uint256) public maxIndex;

    /** Mapping from NFT token ID to owner address */
    mapping(uint256 => address) private _nftOwners;

    /** Mapping from token ID to approved address */
    mapping(uint256 => address) private _tokenApprovals;

    /** inherited BEP1155 `_uri` is private, so need our own within this contract */
    string private _baseTokenURI;

    /**
     * mapping from type ID | index => custom token URIs for non-fungible tokens
     * fallback behavior if missing is to use the default base URI
     */
    mapping (uint256 => string) private _nfTokenURIs;

    /** nft total supply limitation. */
    uint256 private constant _nftTotalSupplyLimit = 999999;

    /**
     * mapping from type ID totalSupply
     * totalSupply[0] : fungible token
     * totalSupply[1] : nonFungible token
     */
    mapping (uint256 => uint256) private _totalSupply;

    /** last token Id minted by user */
    uint256 public _lastTokenId;

    event TokenPoolCreation(address indexed operator, uint256 indexed type_id);


    /**
     * check token id that is fungible or not.
     * id : token id
     * It returns bool value for fungible or non-fungible.
     */
    function isFungible(uint256 id) internal pure returns(bool) {
        return id & TYPE_NF_BIT == 0;
    }

    /**
     *  check token id that is non-fungible or not.
     * id : token id
     * It returns bool value for fungible or non-fungible.
     */
    function isNonFungible(uint256 id) internal pure returns(bool) {
        return id & TYPE_NF_BIT == TYPE_NF_BIT;
    }

    /** Only the creator of a token type is allowed to mint it. */
    modifier creatorOnly(uint256 type_id) {
        require(creators[type_id] == _msgSender(), "Only the creator of a token type is allowed to mint it.");
        _;
    }

    /**
     *  constructor
     * nftUri : Base Token Uri
     */
    constructor(string memory nftUri , address _token , uint256 _minting_price) BEP1155(nftUri) {

        _decimal = 10 ** 18;

        _name = "GameRee";
        _symbol = "GR";

        _fungibleTokenName = "GBPG";
        _nonFungibleTokenName = "GRE";

        _baseTokenURI = nftUri;
        _lastTokenId = 0;

        _totalSupply[0] = 1000000; // total supply for fungible token is 1000000.

        token = _token;
        minting_price = _minting_price;

        // assgin total supply to owner
        uint256 type_id = create(true);
        _mint(owner(), type_id, _totalSupply[0], "");
    }

    function setMintingPrice(uint256 _minting_price) public onlyOwner {
        minting_price = _minting_price;
    }

    function setTokenAddress(address _token) public onlyOwner {
         require(token != address(0),"cannot set to zero");
         token = _token;
    }

    /** get contract symbol */
    function contractName () external view returns(string memory) {
        return _name;
    }

    /** get contract symbol */
    function contractSymbol() external view returns (string memory) {
        return _symbol;
    }
    
    /** get fungible token name */
    function getFungibleTokenName() external view returns (string memory) {
        return _fungibleTokenName;
    }

    /** get non-fungible token name */
    function getNonFungibleTokenName() external view returns (string memory) {
        return _nonFungibleTokenName;
    }

    /** change token name */
    function changeTokeName (string memory tokenName, bool isFungibleToken) external onlyOwner {
        if(isFungibleToken) {
            _fungibleTokenName = tokenName;
        }
        else {
            _nonFungibleTokenName = tokenName;
        }
    }

    /** Override supportInterface (BEP165) */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(BEP1155, IBEP165) returns (bool) {
        return
            interfaceId == type(IBEP1155Mixed).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     *  regisger token creators
     * the user can mint NFT token but only owner can create fungible token.
     * is_fungible : bool value
     * returns type_id : token type id which represnet fungible or non-fungible
     */
    function create(bool is_fungible)
        public
        virtual
        override
        returns(uint256 type_id)
    {
        type_id = (++nonce << 128);
        if(is_fungible) {
            require(_msgSender() == owner(), "BEP1155: Only owner can create fungible token.");
            creators[type_id] = owner();
        }
        else {
            type_id = type_id | TYPE_NF_BIT;
            console.log(type_id);
            creators[type_id] = _msgSender();
        }

        emit TokenPoolCreation(_msgSender(), type_id);
    }

    /**
     *  Set token URI for NFT.
     * type_id : should be Nonfungible type, id: token Id, uri : token uri
     */
    function _setNonFungibleURI(uint256 type_id, uint256 id, string memory _uri)
        public
        virtual
        //creatorOnly(type_id)
    {
        require(isNonFungible(type_id), "BEP1155Mixed: id does not represent a non-fungible type");
        _nfTokenURIs[id] = _uri;
    }

    /**
     *  mint non fungible token without uri
     * type_id : token type id, to: array of addresses to get tokens, data: metadata
     * creatorOnly(type_id)
     */
    function mintNonFungible(uint256 type_id, address[] memory to, bytes memory data)
        external
        virtual
        override
        
    {
        require(isNonFungible(type_id), "BEP1155Mixed: id does not represent a non-fungible type.");
        require(_totalSupply[1] < _nftTotalSupplyLimit, "GameRee1155: total supply is over.");
        //IBEP20(token).transferFrom(_msgSender(),address(this),minting_price);
        
        // Indexes are 1-based.
        uint256 index = maxIndex[type_id] + 1;
        console.log(index);
        console.log(type_id);
        maxIndex[type_id] = SafeMath.add(to.length, maxIndex[type_id]);

        for (uint256 i = 0; i < to.length; ++i) {
            
            console.log(type_id | index + i);

            _mint(to[i], type_id | index + i, 1, data);
            _nftOwners[type_id | index + i] = to[i];
            _totalSupply[1] = SafeMath.add(_totalSupply[1], 1);

            _lastTokenId = type_id | index + i;
        }
    }

    /**
     *  mint non fungible token with uri
     * type_id : token type id, to: array of addresses to get tokens, data: metadata, uri: token uri
     */
    function mintNonFungibleWithURI(uint256 type_id, address[] memory to, bytes memory data, string memory _uri)
        public
        virtual
        override
    {
        require(isNonFungible(type_id), "BEP1155MixedFungible: id does not represent a non-fungible type");
        require(_totalSupply[1] < _nftTotalSupplyLimit, "GameRee1155: total supply is over.");
        //IBEP20(token).transferFrom(_msgSender(),address(this),minting_price);

        // Indexes are 1-based.
        uint256 index = maxIndex[type_id] + 1;
        maxIndex[type_id] = SafeMath.add(to.length, maxIndex[type_id]);
        uint256 id ; 
        for (uint256 i = 0; i < to.length; ++i) {
            id = type_id | index + i;
            
            _mint(to[i], id, 1, data);
            _setNonFungibleURI(type_id, id, _uri);
            _nftOwners[type_id |index + i] = to[i];
            _totalSupply[1] = SafeMath.add(_totalSupply[1], 1);

            _lastTokenId = type_id | index + i;
        }
    }

   /**
     *  mint fungible token
     * type_id : token type id, to: array of addresses to get tokens, data: metadata
     */
    function mintFungible(uint256 type_id, address[] memory to, uint256[] memory amounts, bytes memory data)
        external
        virtual
        override
        creatorOnly(type_id)
    {
        require(isFungible(type_id), "BEP1155Mixed: id does not represent a fungible type");
        require(to.length == amounts.length, "BEP1155Mixed: to and amounts length mismatch");

        for (uint256 i = 0; i < to.length; ++i) {
            _mint(to[i], type_id, amounts[i], data);
            _totalSupply[0] = SafeMath.add(_totalSupply[0], amounts[i]);
            _lastTokenId = type_id;
        }
    }

    // get owner for tokenId
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        if(isFungible(tokenId)) {
            return owner();
        }
        else {
            address nftOwner = _nftOwners[tokenId];
            require(nftOwner != address(0), "BEP1155: invalid token ID");
            return nftOwner;
        }
       
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        super.safeTransferFrom(from,to,id,amount,data);
        _nftOwners[id] = to;
    }

    /** get last token id */
    function getLastTokenId() public view returns (uint256) {
        return _lastTokenId;
    }

    /** override setArpprovalForAll. (BEP1155) */
    function setApprovalForAllWithData(address operator, bool approved)
        external
        virtual
        override
    {
        setApprovalForAll(operator, approved);
    }

    /**
     *  approve nft tokens.
     */
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "GameRe1155: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "GameRe1155: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }
    
    
    /**
     * Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
    }

    /**
     * Get total supply.
     * tokeType = 0, fungiable total supply.
     * tokeType = 1, non fungible total supply.
     */
    function totalSupply(uint256 tokenType) external view returns(uint256) {
        return _totalSupply[tokenType];
    }

    /** Get URI for NFT */
    function uri(uint256 id) public view virtual override(IBEP1155Mixed, BEP1155) returns (string memory) {
        string memory _tokenUri = _nfTokenURIs[id];
        bytes memory tempURITest = bytes(_tokenUri);

        if (tempURITest.length == 0) {
            return _baseTokenURI;
        } else {
            return _tokenUri;
        }
    }

    /** return BaseTokenUri. */
    function baseTokenUri() public view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /** return token amount of owner by token Id. */
    function tokenOwnerById(uint256 id) external view returns (uint256) {
        return balanceOf(owner(), id);
    }

    /**
     * Award nft to recipient.(mint nft to recipient)
     * recipient is address who can get NFT, hash: Token hash, metadata : metadata
     * recipient should not be zero.
     */
    function awardItem(address recipient, string memory hash, string memory metadata) external {
        require(recipient != address(0), "BEP1155: award itme to the zero address");
        uint256 type_id = create(false);

        address[] memory to = new address[](1);
        to[0] = recipient;
        bytes memory data = bytes(hash);

        mintNonFungibleWithURI(type_id, to, data, metadata);
    }
}