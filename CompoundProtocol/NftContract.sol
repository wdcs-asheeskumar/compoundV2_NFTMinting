// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/compound-finance/compound-protocol/blob/master/contracts/Comptroller.sol";
import "https://github.com/compound-finance/compound-protocol/blob/master/contracts/CErc20.sol";
import "https://github.com/compound-finance/compound-protocol/blob/master/contracts/CEther.sol";

contract NFT is ERC721, Ownable {
    IERC20 public token;
    CErc20 public cToken;
    uint256 private _nextTokenId;
    address public admin;
    uint256 public collection;
    mapping(uint256 => uint256) public amountDepositcT;
    mapping(uint256 => uint256) public amountDepositT;
    mapping(uint256 => uint256) public startDate;
    mapping(uint256 => uint256) public endDate;

    constructor(
        address initialOwner,
        address _token,
        address _cToken,
        address _admin
    ) ERC721("MyNewCar", "MNCR") Ownable(initialOwner) {
        token = IERC20(_token);
        cToken = CErc20(_cToken);
        admin = _admin;
    }

    function _baseURI() internal pure override returns (string memory) {
        return
            "https://ipfs.io/ipfs/QmYT2YHTXTw9ZEhS1xnuCGnAykDrUqiViHSZVHFmjLXenE/";
    }

    function safeMint(address to, uint256 _amount) public onlyOwner {
        token.transferFrom(msg.sender, address(this), _amount);
        token.approve(address(cToken), _amount);
        uint256 rate = cToken.exchangeRateCurrent();
        uint256 cTokenAmount = _amount / rate;
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        amountDepositcT[tokenId] = cTokenAmount;
        amountDepositT[tokenId] = _amount;
        startDate[tokenId] = block.timestamp;
    }

    function burnToken(
        uint256 tokenId,
        uint256 _amount,
        uint256 _days
    ) external {
        uint256 rate = cToken.supplyRatePerBlock();
        uint256 dailySupplyRate = rate * 5760;
        uint256 interest = amountDepositT[tokenId] * dailySupplyRate * _days;
        collection = interest;
        cToken.redeem(_amount);
        _burn(tokenId);
    }

    function adminFeesCollection() public {
        token.transferFrom(address(this), admin, collection);
    }
}
