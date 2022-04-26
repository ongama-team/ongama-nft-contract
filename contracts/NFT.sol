// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721, Ownable {
    address payable public _contractOwner;
    uint256 public tokenCounter;
    
    mapping(uint => string) public tokenURIMap;
    mapping(uint => uint) public priceMap;
    mapping(uint => bool) public listedMap;

    event Minted(address indexed minter, uint price, uint nftID, string uri);
        
    event PriceUpdate(address indexed owner, uint oldPrice, uint newPrice, uint nftID);

    event NftListStatus(address indexed owner, uint nftID, bool isListed);

    event Purchase(address indexed previousOwner, address indexed newOwner, uint price, uint nftID, string uri);

    constructor() ERC721("OngamaNFTs", "ONGA") {
        _contractOwner = payable(msg.sender);
        tokenCounter = 1;
    }

    function mint(string memory _tokenURI, address _toAddress, uint _price) public returns (uint) {
        uint _tokenId = tokenCounter;
        priceMap[_tokenId] = _price;
        listedMap[_tokenId] = true;

        _safeMint(_toAddress, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);

        tokenCounter++;

        emit Minted(_toAddress, _price, _tokenId, _tokenURI);

        return _tokenId;
    }

    function buy(uint _id) external payable {
        _validate(_id);

        address _previousOwner = ownerOf(_id);
        address _newOwner = msg.sender;

        _trade(_id);

        emit Purchase(_previousOwner, _newOwner, priceMap[_id], _id, tokenURI(_id));
    }

    function _setTokenURI(uint256 _tokenId, string memory _tokenURI) internal virtual {
        require(_exists(_tokenId),"ERC721Metadata: URI set of nonexistent token"); 
        tokenURIMap[_tokenId] = _tokenURI;
    }

    function _validate(uint _id) internal {
        bool _isItemListed = listedMap[_id];
        require(_exists(_id), "Error, wrong tokenId");
        require(_isItemListed, "Item not listed currently");
        require(msg.value >= priceMap[_id], "Error, the amount is lower");
        require(msg.sender != ownerOf(_id), "Can not buy what you own");
    }

    function _trade(uint _id) internal {
        address payable _buyer = payable(msg.sender);
        address payable _owner = payable(ownerOf(_id));

        // Unlist NFT before transferring during a trade
        listedMap[_id] = false;
        _transfer(_owner, _buyer, _id);

        // 5% commission cut
        uint _commissionValue = priceMap[_id] / 20;
        uint _sellerValue = priceMap[_id] - _commissionValue;

        _owner.transfer(_sellerValue);
        _contractOwner.transfer(_commissionValue);

        // If buyer sent more than price, we send them back their rest of funds
        if (msg.value > priceMap[_id]) {
            _buyer.transfer(msg.value - priceMap[_id]);
        }
    }

    function updatePrice(uint _tokenId, uint _price) public returns (bool) {
        uint oldPrice = priceMap[_tokenId];
        require(msg.sender == ownerOf(_tokenId), "Error, you are not the owner");
        require(oldPrice == _price, "Error,new price should not be equal to old price");
        priceMap[_tokenId] = _price;

        emit PriceUpdate(msg.sender, oldPrice, _price, _tokenId);

        return true;
    }

    function updateListingStatus(uint _tokenId, bool shouldBeListed) public returns (bool) {
        require(msg.sender == ownerOf(_tokenId), "Error, you are not the owner");

        listedMap[_tokenId] = shouldBeListed;

        emit NftListStatus(msg.sender, _tokenId, shouldBeListed);

        return true;
    }

}
