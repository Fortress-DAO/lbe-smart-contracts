// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract FORTSale is Ownable {

    using SafeERC20 for ERC20;
    using Address for address;

    uint constant MIMdecimals = 10 ** 18;
    uint constant FORTdecimals = 10 ** 9;
    uint public constant MAX_SOLD = 70000 * FORTdecimals;
    uint public constant PRICE = 5 * MIMdecimals / FORTdecimals ;
    uint public constant MAX_SALE_PER_ACCOUNT = 100 * FORTdecimals;
    uint public constant MAX_PRESALE_PER_ACCOUNT = 200 * FORTdecimals;

    uint public sold;
    uint owed;
    address public FORT;

    mapping(address => uint256 ) public invested;

    address public dev;

    ERC20 MIM;

    uint presaleTimestamp;

    mapping( address => bool ) public approvedBuyers;

    constructor( address _dev, uint _presaleTimestamp, address mim_address) {
        dev = _dev;
        presaleTimestamp = _presaleTimestamp;
        MIM = ERC20(mim_address);
    }


    modifier onlyEOA() {
        require(msg.sender == tx.origin, "!EOA");
        _;
    }

    function _approveBuyer( address newBuyer_ ) internal onlyOwner() returns ( bool ) {
      approvedBuyers[newBuyer_] = true;
      return approvedBuyers[newBuyer_];
    }

    function approveBuyer( address newBuyer_ ) external onlyOwner() returns ( bool ) {
      return _approveBuyer( newBuyer_ );
    }

    function approveBuyers( address[] calldata newBuyers_ ) external onlyOwner() returns ( uint256 ) {
      for( uint256 iteration_ = 0; newBuyers_.length > iteration_; iteration_++ ) {
        _approveBuyer( newBuyers_[iteration_] );
      }
      return newBuyers_.length;
    }

    function isPresale() public view returns (bool) {
        if ( presaleTimestamp <= block.timestamp){
          return true;
        }
        return false;
    }

    function isPublicSale() public view returns (bool) {
      if (presaleTimestamp + 24 * 3600 <= block.timestamp) {
        return true;
      }
      return false;

    }

    function amountBuyable(address buyer) public view returns (uint256) {
        uint256 max;
        if (approvedBuyers[buyer] && isPresale() ){
          max = MAX_PRESALE_PER_ACCOUNT;
        }
        if (!approvedBuyers[buyer] && isPublicSale() ){
          max = MAX_SALE_PER_ACCOUNT;
        }
        return max - invested[buyer];
      }


    function buyFORT(uint256 amount) public onlyEOA {
        require(sold < MAX_SOLD, "sold out");
        require(sold + amount < MAX_SOLD, "not enough remaining");
        require(amount <= amountBuyable(msg.sender), "amount exceeds buyable amount");
        MIM.safeTransferFrom( msg.sender, address(this), amount * PRICE  );
        invested[msg.sender] += amount;
        sold += amount;
        owed += amount;
    }

    function claimFORT() public onlyEOA {
      ERC20(FORT).transfer(msg.sender, invested[msg.sender]);
      owed -= invested[msg.sender];
      invested[msg.sender] = 0;

    }
    function setClaimingActive(address fort) public {
        require(msg.sender == dev, "!dev");
        FORT = fort;
    }

    function withdraw(address _token) public {
        require(msg.sender == dev, "!dev");
        uint b = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(dev,b);
    }


    function getCurrentTimestamp() view external  returns(uint){
        return block.timestamp;
    }

}
