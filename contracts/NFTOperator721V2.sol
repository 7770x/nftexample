// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface INFT721 {
    function createToken(string memory tokenURI) external returns (uint256);
}

contract NFTOperator721V2 is
    Initializable,
    ERC721Upgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ERC721HolderUpgradeable
{
    using SafeMath for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _itemIds;
    CountersUpgradeable.Counter private _itemsSold;
    address TAddress;
    address XAddress;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __Ownable_init();
        __Pausable_init();
    }

    struct GameItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address seller;
        address owner;
        bool sold;
    }

    mapping(uint256 => GameItem) private idToGameItem;

    event AddressesAndParamsSet(address TAddress, address XAddress);

    event GameItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        bool sold
    );

    function setAddressesAndParameters(
        address PassedTAddress,
        address PassedXAddress
    ) public onlyOwner {
        TAddress = PassedTAddress;
        XAddress = PassedXAddress;

        emit AddressesAndParamsSet(TAddress, XAddress);
    }

    function createGameItem(address nftContract, string memory tokenURI)
        public
        onlyOwner
        returns (uint256)
    {
        uint256 tokenId = INFT721(nftContract).createToken(tokenURI);

        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        idToGameItem[itemId] = GameItem(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            false
        );

        emit GameItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            false
        );
        return tokenId;
    }

    function mintWeapon(address nftContract, uint256 itemId) public payable {
        uint256 tokenId = idToGameItem[itemId].tokenId;

        IERC721Upgradeable(nftContract).transferFrom(
            address(this),
            msg.sender,
            tokenId
        );
        idToGameItem[itemId].owner = payable(msg.sender);
        idToGameItem[itemId].sold = true;
        _itemsSold.increment();
    }

    function mintWeaponWithAddress(
        address nftContract,
        uint256 itemId,
        address recipient
    ) public payable {
        uint256 tokenId = idToGameItem[itemId].tokenId;

        IERC721Upgradeable(nftContract).transferFrom(
            address(this),
            recipient,
            tokenId
        );
        idToGameItem[itemId].owner = payable(recipient);
        idToGameItem[itemId].sold = true;
        _itemsSold.increment();
    }

    function fetchGameItems() public view returns (GameItem[] memory) {
        uint256 itemCount = _itemIds.current();

        uint256 unsoldItemCount = _itemIds.current() - _itemsSold.current();

        uint256 currentIndex = 0;

        GameItem[] memory items = new GameItem[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (idToGameItem[i + 1].owner == address(0)) {
                uint256 currentId = i + 1;
                GameItem storage currentItem = idToGameItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    function fetchMyNFTs() public view returns (GameItem[] memory) {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToGameItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        GameItem[] memory items = new GameItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToGameItem[i + 1].owner == msg.sender) {
                uint256 currentId = i + 1;
                GameItem storage currentItem = idToGameItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchNFTsOfUser(address user)
        public
        view
        returns (GameItem[] memory)
    {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToGameItem[i + 1].owner == user) {
                itemCount += 1;
            }
        }

        GameItem[] memory items = new GameItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToGameItem[i + 1].owner == user) {
                uint256 currentId = i + 1;
                GameItem storage currentItem = idToGameItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchNFTById(uint256 itemId)
        public
        view
        returns (GameItem memory)
    {
        GameItem storage currentItem = idToGameItem[itemId];

        return currentItem;
    }

    function fetchItemsCreated() public view returns (GameItem[] memory) {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToGameItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        GameItem[] memory items = new GameItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToGameItem[i + 1].seller == msg.sender) {
                uint256 currentId = i + 1;
                GameItem storage currentItem = idToGameItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function test() public pure returns (uint8) {
        return 21;
    }
}
