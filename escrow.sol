// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC1155ASSIGNMENT.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./Iescrow.sol";

contract escrowcontract is ERC1155Holder, iescrow {
    address payable admin;
    address tokenaddress;
    uint ordernumber;

    struct Order {
        address seller;
        uint tokenid;
        uint amount;
        uint pricepernft;
        SaleType saletype;
        uint timeline;
    }

    struct Bid {
        address bidder;
        uint bidvalue;
        uint timestamp;
    }

    mapping(uint => Order) public orderMapping;
    // mapping(uint => mapping(uint => Bid)) bidMapping;
    mapping(uint => Bid) public bidMapping;
    mapping(uint => uint) tokenCopiesMapping;
    mapping(uint=>Bid) order_bid;

    event orderplaced(Order order, uint orderNumber, uint timeStamp,  address seller);
    event placebid(uint ordernumber, uint _amount, address bidder, uint timestamp);
    event orderbought(uint ,uint ,uint,address ,address);

    constructor(address _tokenaddress) {
        admin = payable(msg.sender);
        tokenaddress = _tokenaddress;
        ordernumber = 1;
    }

    function placeorder( address _nftaddress , uint _tokenid,address _seller,uint _amount,uint _pricepernft) public {
        Order memory order = Order({
            seller: _seller,
            tokenid:_tokenid,
            amount:_amount,
            pricepernft:_pricepernft,
            saletype:GetSaleType(_nftaddress,_tokenid),
            timeline: block.timestamp
        });
        orderMapping[ordernumber] = order;
        ERC1155(_nftaddress).safeTransferFrom( _seller, address(this), _tokenid, _amount, "" );
        emit orderplaced(order,ordernumber,block.timestamp,_seller);
        ordernumber++;
    }

  
    function buynow( address _nftaddress, uint _ordernumber,uint _copynumber) external payable {
        uint tokenId = orderMapping[_ordernumber].tokenid;
        Order memory order = orderMapping[_ordernumber];
        require(msg.sender != order.seller,"Buyer cannot be the seller");
        // require(keccak256(bytes(order.saletype)) == keccak256(bytes("buynow")),"Incorrect sale type");
        require(orderMapping[_ordernumber].saletype==SaleType.Instant,"SaleType is not INSTANT.");
        if(get_payment_method(_nftaddress,_ordernumber)==true)
        {
            require(IERC20(MyToken(_nftaddress).paymenttoken()).balanceOf(
                msg.sender)>=_copynumber,"you have to pay more");
            IERC1155(_nftaddress).safeTransferFrom( address(this), msg.sender, order.tokenid, _copynumber, "" );    
            IERC20(MyToken(_nftaddress).paymenttoken()).transferFrom(msg.sender,orderMapping[_ordernumber].seller,_copynumber);
        }
        else
        {
            require(msg.value==_copynumber * orderMapping[_ordernumber].pricepernft,"pay price for buy");
            IERC1155(_nftaddress).safeTransferFrom(address(this),msg.sender,tokenId,_copynumber,"");
            payable(orderMapping[_ordernumber].seller).transfer(msg.value);
        }
        // address _from = orderMapping[_ordernumber].seller;
        // uint _tokenId = orderMapping[_ordernumber].tokenid;
        // IERC1155(_nftaddress).safeTransferFrom(_from,msg.sender,_tokenId,_copynumber,"");
        // require(msg.value == order.pricepernft * _copynumber,"Incorrect payment amount");
        // IERC20(tokenaddress).transferFrom(address(this),msg.sender,order.tokenid);
        orderMapping[_ordernumber].amount -= _copynumber;
        emit orderbought(_ordernumber,_copynumber,block.timestamp,msg.sender,address(this));
    }

    function placeBid(uint _ordernumber,uint _amount) public {
        Order memory order = orderMapping[_ordernumber];
        require(msg.sender != order.seller,"seller cannot place a bid");
        // require(keccak256(bytes(order.saletype)) == keccak256(bytes("Auction")),"Incorrect sale type");
        require(orderMapping[_ordernumber].saletype==SaleType.Auction,"SaleType is not AUCTION.");
        require(_amount >= order.pricepernft,"bid value is lower than the minimum bid amount");
        // require (_amount >= bidMapping[_ordernumber][_amount].bidvalue + order.pricepernft,"bid value is lower than the current highest bid");
        require(_amount > bidMapping[_ordernumber].bidvalue,"Enter High bid amount.");
        Bid memory bid = Bid({
            bidder: msg.sender,
            bidvalue:_amount,
            timestamp:block.timestamp   
        });
        bidMapping[_ordernumber] = bid;
        // bidMapping[_ordernumber][_amount] = bid;
        emit placebid(_ordernumber,_amount,msg.sender,block.timestamp);
    }

    function claimBid(uint _ordernumber,address _tokenaddress) public payable {
        address _seller = orderMapping[_ordernumber].seller;
        require(bidMapping[_ordernumber].bidder == msg.sender,"you are not bidder");
        require(orderMapping[_ordernumber].timeline<=block.timestamp,"Time line is not over");
        //require((orderMapping[_ordernumber].pricepernft * orderMapping[_ordernumber].amount)<=msg.value,"you have to pay first");
        uint _tokenid = orderMapping[_ordernumber].tokenid;

        IERC1155(_tokenaddress).safeTransferFrom(address(this),msg.sender,_tokenid, orderMapping[_ordernumber].amount,"");

        orderMapping[_ordernumber].amount = 0;
        if(get_payment_method(_tokenaddress, _ordernumber)==true) 
        {
            IERC20(MyToken(_tokenaddress).paymenttoken()).transferFrom(msg.sender,orderMapping[
                _ordernumber].seller,orderMapping[_ordernumber].amount);
        }
        else    
        {
            require(msg.value == bidMapping[ordernumber].bidvalue,"Enter correct value.");
            payable(_seller).transfer(msg.value);
        }
        emit orderbought(ordernumber,orderMapping[_ordernumber].amount,block.timestamp,msg.sender,address(this));
    }

    function get_payment_method(address nft, uint _ordernumber) public view returns(bool)
    {
        return MyToken(nft).paymentmethod(orderMapping[_ordernumber].tokenid);
    }

    function GetSaleType(address _nftaddress,uint id) private view returns(SaleType)
    {
        return MyToken(_nftaddress).getSaletype(id);
    }
}