pragma solidity ^0.8.28;

import "./ProductTypes.sol";

/**
Defnining all functions and events for Retailer needed to be performed
in supply chain smart contract

It extends the ProductTypes interface for access to shared data structures
and lifecycle enums. Implemented by the main contract to handle retailer
actions such as inventory intake, sales, and returns.
**/


interface RetailerActions is ProductTypes{
    function RETAILER_ROLE() external view returns (bytes32);

    error NotAuthorized();
    error InvalidState();
    error NotCurrentHolder();
    error UnknownProduct();

    event InventoryReceived(
        uint256 indexed productId,
        address indexed retailer,
        uint32 receiveDate
    );
    event ProductSold(
        uint256 indexed productId,
        bytes32 receiptId,
        uint32 saleDate
    );
    event ReturnProcessed(
        uint256 indexed productId,
        bytes32 returnId,
        uint32 returnDate
    );

    function receiveInventory(
        uint256[] calldata productIds,
        uint32 receiveDate
    ) external;

    function markAsSold(
        uint256 productId,
        bytes32 receiptId,
        uint32 saleDate
    ) external;

    function processReturn(
        uint256 productId,
        bytes32 returnId,
        uint32 returnDate
    ) external;
}