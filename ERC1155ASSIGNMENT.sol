// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Iescrow.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

enum SaleType{Auction,Instant}

contract MyToken is ERC1155, Ownable {

    struct token {
        uint256 maxcopies;
        string uri;
        SaleType saletype;
        bool paymenttokenenabled;
    }
    address public escrowaddress;
    mapping(uint256 => token) public tokens;
    mapping(uint256 => string) private tokenuri;
    // bool public paymentMethod=true;

    IERC20 public paymenttoken;
    mapping(uint256 => bool) public paymenttokenenabled;

    constructor(address _paymenttoken,address _escrowcontract) ERC1155("") {
        paymenttoken = IERC20(_paymenttoken);
        escrowaddress = _escrowcontract;
    }

    function paymentmethod(uint tokenid) public view returns(bool) {
            return paymenttokenenabled[tokenid];
    }

    function setURI(uint256 id ,string memory newuri) public onlyOwner {
        tokenuri[id]= newuri;
    }

    function GetTokenUri (uint256 id) public view returns(string memory) {
        return tokenuri[id];
    }

    function enablepaymenttoken(uint _tokeId) public onlyOwner {
       paymenttokenenabled[_tokeId] = true;
    }

    function disablepaymenttoken(uint _tokeId) public onlyOwner {
        paymenttokenenabled[_tokeId] = false;
    }

    function gettokenuri(uint256 tokenid) public view returns (string memory)
    {
        return uri(tokenid);
    }

    function minttoken(uint256 tokenid,uint256 numberofcopies,string memory tokenurii,
                       SaleType saletype,uint256 pricepernft) public {
        require(numberofcopies > 0,"Number of copies greater than 0");
        require(bytes(tokenurii).length > 0,"token uri greater than 0");
        require(pricepernft > 0,"price per nft greater than 0");
        require(saletype == SaleType.Auction || saletype == SaleType.Instant,"sale type should be Auction and Instant");
        setApprovalForAll(escrowaddress, true);
       tokens[tokenid] = token(
            numberofcopies,
            tokenurii,
            saletype,
            true
       );

        _mint(msg.sender, tokenid, numberofcopies, "");

        iescrow(escrowaddress).placeorder(address(this), tokenid, msg.sender, numberofcopies, pricepernft);
    } 

    function getSaletype(uint id) public view returns(SaleType)
    {
        return tokens[id].saletype;
    }
}
