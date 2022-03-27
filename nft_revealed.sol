// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


//https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC721

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MintNftToken is  ERC721Enumerable {
    using Counters for Counters.Counter;

    bool public revealed = false;
    string defaultURI;
    string notRevealedUri;

    address[] private minterArray;

    Counters.Counter private _tokenIds;
    //constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}
    constructor() ERC721("iki", "jquery_symbol") {
        _addMinter(msg.sender);
    }


    // Reveal function 
    function _defaultURI() internal view returns (string memory) {
      return defaultURI;
    }

    function _notRevealedURI() internal view returns (string memory) {
      return notRevealedUri;
    }


    function setBaseURI(string memory _newBaseURI) public  onlyMinter{
      defaultURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _newNotRevealedURI) public  onlyMinter{
       notRevealedUri = _newNotRevealedURI;
    }
    // Reveal function 

    //Role function
    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);



    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
        _;
    }


    function isMinter(address account) public view returns (bool) {
        bool isMinterYn = false;

        for(uint i = 0; i < minterArray.length; i ++){
            if(minterArray[i] == account){
                isMinterYn = true;
            }          
        } 
        return isMinterYn ;
    }

    function addMinter(address account) public onlyMinter{
         _addMinter(account);
    }

    function getMinters() public view returns(address[] memory){
        return minterArray ;
    }


    function _addMinter(address account) internal {
        minterArray.push(account);
        emit MinterAdded(account);
    }
    //Role function
    

    mapping(uint =>string ) public tokenURIs ;

    function tokenURI(uint _tokenId) override public view returns (string memory) {


      if(revealed == false) {
        string memory currentNotRevealedUri = _notRevealedURI();


        return bytes(currentNotRevealedUri).length > 0
            ? string( abi.encodePacked(currentNotRevealedUri, '/', Strings.toString(_tokenId), '.json') ) 
            : "";
      }
      string memory currentBaseURI = _defaultURI();

     
      return bytes(currentBaseURI).length > 0
          ? string( abi.encodePacked(currentBaseURI, '/', Strings.toString(_tokenId), '.json') ) 
          : "";
    }



    function reveal(bool _state)  public onlyMinter {
      revealed = _state;
    }



    function getReveal()  public view returns(bool) {
      return revealed;
    }



    function mintNFT() public onlyMinter returns (uint256) {
        _tokenIds.increment();
        uint256 _tokenId = _tokenIds.current();
        string memory currentNotRevealedUri = _notRevealedURI();
        string memory currentBaseURI = _defaultURI();


        if(revealed == false) {
            tokenURIs[_tokenId] = string( abi.encodePacked(currentNotRevealedUri, '/', Strings.toString(_tokenId), '.json') ) ;
        }else{
            tokenURIs[_tokenId] = string( abi.encodePacked(currentBaseURI, '/', Strings.toString(_tokenId), '.json') ) ;
        }

        _mint(msg.sender, _tokenId);
        return _tokenId;
    }




    //Airdrop Mint
    function airDropMint(address user, uint256 requestedCount) external onlyMinter {
      require(requestedCount > 0, "zero request");
      for(uint256 i = 0; i < requestedCount; i++) {
        _tokenIds.increment();
        uint256 _tokenId = _tokenIds.current();
        string memory currentNotRevealedUri = _notRevealedURI();
        string memory currentBaseURI = _defaultURI();

        if(revealed == false) {
            tokenURIs[_tokenId] = string( abi.encodePacked(currentNotRevealedUri, '/', Strings.toString(_tokenId), '.json') ) ;
        }else{
            tokenURIs[_tokenId] = string( abi.encodePacked(currentBaseURI, '/', Strings.toString(_tokenId), '.json') ) ;
        }


        _mint(user, _tokenId);
      }
    }


 




    struct NftTokenData {
        uint256 nftTokenId;
        string  nftTokenURI ;
        uint price ;
    }
    
    function getSaleNftTokens() public view returns (NftTokenData[] memory ){
        uint[] memory onSaleNftToken = getSaleNftToken();
        
        //require(onSaleNftToken.length > 0 ,"Not exist on sale token.");

        NftTokenData[] memory onSaleNftTokens = new NftTokenData[](onSaleNftToken.length);

        for(uint i = 0; i < onSaleNftToken.length; i ++){
            uint tokenId = onSaleNftToken[i];
            
            uint tokenPrice = getNftTokenPrice(tokenId);
            onSaleNftTokens[i] = NftTokenData(tokenId, tokenURI(tokenId), tokenPrice) ;
        }
        return onSaleNftTokens;
    }


    //setApprovalForAll :: 컨트랙트 주소 , flase/true
    //isApprovedForAll 에서 확인





    function getNftTokens(address _nftTokenOwner) view public returns (NftTokenData[] memory) {
        uint256 balanceLength = balanceOf(_nftTokenOwner);

        //require(balanceLength != 0, "Owner did not have token.");
        
            NftTokenData[] memory nftTokenData = new NftTokenData[](balanceLength);

            for(uint256 i = 0; i < balanceLength; i++) {
                uint256 nftTokenId = tokenOfOwnerByIndex(_nftTokenOwner, i);
                //string memory nftTokenURI = tokenURIs[nftTokenId];
                string memory nftTokenURI = tokenURI(nftTokenId);

                uint tokenPrice = getNftTokenPrice(nftTokenId);
                nftTokenData[i] = NftTokenData(nftTokenId , nftTokenURI, tokenPrice);
            }
            
            return nftTokenData;

    }




    function burn( uint256 _tokenId) external {
        address addr_owner = ownerOf(_tokenId);
        require(
            addr_owner == msg.sender,
            "msg.sender is NOT the owner of the token"
        );

        _burn(_tokenId);

        //판매 리스트에서 삭제
        removeToken(_tokenId);
  
    }



    
    //판매 등록
    mapping(uint256 => uint256) public nftTokenPrices;
    uint256[] public onSaleNftTokenArray;

    function setSaleNftToken(uint256 _tokenId, uint256 _price) public {
        address nftTokenOwner = ownerOf(_tokenId);

        require(nftTokenOwner == msg.sender, "Caller is not nft token owner.");
        require(_price > 0, "Price is zero or lower.");
        require(nftTokenPrices[_tokenId] == 0, "This nft token is already on sale.");
        require(isApprovedForAll(nftTokenOwner, address(this)), "nft token owner did not approve token.");

        nftTokenPrices[_tokenId] = _price;
        onSaleNftTokenArray.push(_tokenId); //판매중인 nft list
        

    }



   //구매함수
    function buyNftToken(uint256 _tokenId) public payable {
        uint256 price = nftTokenPrices[_tokenId];
        address nftTokenOwner = ownerOf(_tokenId);
        require(price > 0, "nft token not sale.");
        require(price  <= msg.value, "caller sent lower than price.");
        require(nftTokenOwner != msg.sender,"caller is nft token owner.");
        require(isApprovedForAll(nftTokenOwner, address(this)), "nft token owner did not approve token.");

        payable(nftTokenOwner).transfer(msg.value);
        IERC721(address(this)).safeTransferFrom(nftTokenOwner, msg.sender, _tokenId);

        //판매 리스트에서 삭제
        removeToken(_tokenId);

    }

    

    function getSaleNftToken() view public returns (uint[] memory ){
        return onSaleNftTokenArray ;
    }

    function getNftTokenPrice(uint256 _tokenId) view public returns(uint256){
        return nftTokenPrices[_tokenId];
    }


    function removeToken(uint256 _tokenId) private {
                
        nftTokenPrices[_tokenId] = 0;

        for(uint256 i = 0; i<onSaleNftTokenArray.length; i ++){
            if(nftTokenPrices[onSaleNftTokenArray[i]] ==0){
                onSaleNftTokenArray[i] = onSaleNftTokenArray[onSaleNftTokenArray.length -1] ;
                onSaleNftTokenArray.pop();
            }
        }
    }

}