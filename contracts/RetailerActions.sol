pragma solidity ^0.8.28;

import "./ProductTypes.sol";

/**
This file lists everything a RETAILER can do in the supply chain system.

It includes the role name, possible errors, events (for record keeping),
and functions that a retailer is allowed to call.
**/


interface RetailerActions is ProductTypes{

    // ----------- Role ----------------
    // This is a unique code to chekc if someone is Retailer.
    function RETAILER_ROLE() external view returns (bytes32);

    // -------- ERRORS -------------
    // This could help show why a transaction failed.


    error NotAuthorized();   // The Caller doesnt have the permission
    error InvalidState();   // The product is not in the correct stage of action
    error NotCurrentHolder();   // The caller is not the current owner of the product
    error UnknownProduct();   // The product does not exist

    // ---------- EVENTS ---------------
    // These are like logs. They record what happened in blockchain

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