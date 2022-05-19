// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockERC721 is ERC721, Ownable {
    struct AllowedUsers {
        address user;
        uint16 maxCount;
    }

    // maximum number of tokens ever gonna be minted on this contract
    uint16 public MAX_TOTAL_SUPPLY = 10000;

    // price of a single NFT
    uint256 internal MINT_PRICE = 0.05 ether;

    // presale & public sale activation block time & bool
    uint256 public privateMintTime;
    uint256 public publicMintTime;
    bool public privateMintActive = false;

    // default is true - using for sale pausable if something go wrong
    bool public publicMintActive = true;

    // addresses that can participate in the presale event - adress -> max.count
    mapping(address => uint16) private allowedForPrivate;

    // for enumeration minted tokens count
    uint16 internal totalMinted = 0;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    // ONLY OWNER FUNCTIONS

    // activate presale in 60 min & after 24 hours public sale
    function setPrivateSaleActive() external onlyOwner {
        privateMintActive = true;
        privateMintTime = block.timestamp + 3600;

        publicMintTime = privateMintTime + 24 hours;
    }

    // flip presale state
    function flipPrivateSaleState() external onlyOwner {
        privateMintActive = !privateMintActive;
    }

    // flip public sale state
    function flipPublicSaleState() external onlyOwner {
        publicMintActive = !publicMintActive;
    }

    // makes addresses eligible for presale minting
    function addPresaleMembers(AllowedUsers[] calldata _users)
        external
        onlyOwner
    {
        for (uint16 i = 0; i < _users.length; i++) {
            allowedForPrivate[_users[i].user] = _users[i].maxCount;
        }
    }

    function withdraw(address payable recipient, uint256 amount)
        external
        onlyOwner
    {
        recipient.transfer(amount);
    }

    // removes addresses from the presale list
    function removePresaleMembers(address[] calldata _users)
        external
        onlyOwner
    {
        for (uint16 i = 0; i < _users.length; i++) {
            allowedForPrivate[_users[i]] = 0;
        }
    }

    // INTERNAL FUNCTIONS

    // mint token
    function _mintToken(address to, uint16 count) private {
        require(count > 0, "Min mint amount is 1");
        require(
            totalMinted + count <= MAX_TOTAL_SUPPLY,
            "Limit: 10k nft minted"
        );

        for (uint16 i = 0; i < count; i++) {
            _safeMint(to, totalMinted + 1);
            totalMinted += 1;
        }
    }

    // PUBLIC FUNCTIONS

    // presale minting
    function privateMint(address to, uint16 count) external payable {
        require(privateMintActive == true, "Private sale is not active");
        require(
            privateMintTime <= block.timestamp,
            "Private sale is activating..."
        );
        require(
            msg.value == MINT_PRICE * count,
            "Value is not equal to price * count"
        );
        require(allowedForPrivate[to] >= count, "Whitelist mint limit");

        _mintToken(to, count);

        allowedForPrivate[to] -= count;
    }

    // public minting
    function publicMint(address to, uint16 count) external payable {
        require(publicMintActive == true, "Public sale is not active");
        require(publicMintTime <= block.timestamp, "Public sale is not active");
        require(
            msg.value == MINT_PRICE * count,
            "Value is not equal to price * count"
        );

        _mintToken(to, count);
    }

    // VIEW FUNCTIONS

    // total minted tokens count
    function getTotalMintedCount() external view returns (uint16) {
        return totalMinted;
    }

    // allowed for presale addresses with count
    function getAllowedUserCount(address _user) external view returns (uint16) {
        return allowedForPrivate[_user];
    }

    // presale activation status
    function getPrivateSaleStatus() external view returns (bool) {
        if (privateMintTime <= block.timestamp) {
            if (privateMintActive == true) {
                return true;
            }
        }

        return false;
    }

    // public sale status
    function getPublicSaleStatus() external view returns (bool) {
        if (publicMintTime <= block.timestamp) {
            if (publicMintActive == true) {
                return true;
            }
        }

        return false;
    }
}
