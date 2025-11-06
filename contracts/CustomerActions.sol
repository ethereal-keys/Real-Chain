pragma solidity ^0.8.28;

import "./ProductTypes.sol";

/**
This file lists everything a CUSTOMER/CONSUMER can do in the supply chain system.

Customers are end users who purchase products and want to verify authenticity.
They don't need wallets - all their interactions are read-only through a web interface.

They scan QR codes to verify products and view the complete supply chain history.
**/

interface CustomerActions is ProductTypes {

    // ----------- Role ----------------
    // Customers don't have a role since they don't need wallet authentication
    // All customer functions are public view functions
    
    // -------- ERRORS -------------
    // These help show why a verification or query might fail.

    error ProductNotFound();  // The product ID doesn't exist in the system
    error InvalidProductId(); // The product ID format is invalid
    error DataUnavailable();  // Off-chain data cannot be retrieved

    // ---------- EVENTS ---------------
    // These log customer interactions for analytics

    // This event is triggered when a customer scans a product for verification
    event ProductScanned(
        uint256 indexed productId,  // product being verified
        uint32 scanTimestamp,  // when the scan occurred
        bool isAuthentic  // whether product passed authenticity check
    );

    // This event logs when a customer views detailed product history
    event ProductHistoryViewed(
        uint256 indexed productId,  // product whose history was viewed
        uint32 viewTimestamp  // when the history was accessed
    );

    // This event tracks when customers check recall status
    event RecallStatusChecked(
        uint256 indexed productId,  // product being checked
        bool isRecalled,  // whether product is recalled
        uint32 checkTimestamp  // when the check occurred
    );

    // --------------- Functions ----------------

    /**
    Function: verifyAuthenticity
    Called when a customer scans a QR code to verify if a product is genuine.
    Returns authentication status and basic product information.
    This increments the scan counter for analytics.
    **/

    function verifyAuthenticity(
        uint256 productId  // unique product identifier from QR code
    ) external view returns (
        bool isAuthentic,  // whether product is genuine
        ProductStatus currentStatus,  // current status in supply chain
        address manufacturer,  // who made the product
        uint32 manufactureDate  // when it was made
    );

    /**
    Function: getProductDetails
    Retrieves comprehensive product information for customer viewing.
    Returns both on-chain data and pointers to off-chain metadata.
    **/

    function getProductDetails(
        uint256 productId  // product to query
    ) external view returns (
        Product memory productInfo,  // complete product struct
        uint32 scanCount,  // how many times scanned
        uint32 transferCount  // number of ownership changes
    );

    /**
    Function: getProductHistory
    Returns the complete supply chain history of a product.
    Shows all ownership transfers and status changes.
    **/

    function getProductHistory(
        uint256 productId  // product to trace
    ) external view returns (
        address[] memory owners,  // list of all past owners
        ProductStatus[] memory statuses,  // all status transitions
        uint32[] memory timestamps  // when each transition occurred
    );

    /**
    Function: checkRecallStatus
    Checks if a product has been recalled or marked as defective.
    Returns recall information if applicable.
    **/

    function checkRecallStatus(
        uint256 productId  // product to check
    ) external view returns (
        bool isRecalled,  // whether product is recalled
        uint32 recallDate,  // when recall was issued (0 if not recalled)
        bytes32 recallReasonHash  // IPFS hash of recall details
    );

    /**
    Function: batchVerify
    Allows verification of multiple products at once.
    Useful for customers checking multiple items or retail audits.
    **/

    function batchVerify(
        uint256[] calldata productIds  // list of products to verify
    ) external view returns (
        bool[] memory authenticityResults,  // authenticity for each product
        ProductStatus[] memory statusResults  // current status of each
    );

    /**
    Function: getManufacturerInfo
    Returns information about the manufacturer of a product.
    Helps customers verify authorized manufacturers.
    **/

    function getManufacturerInfo(
        uint256 productId  // product to query
    ) external view returns (
        address manufacturerAddress,  // manufacturer's blockchain address
        uint16 factoryId,  // which factory location
        bool isAuthorized  // whether manufacturer is currently authorized
    );

    /**
    Function: getRetailerInfo
    Returns information about where the product was sold.
    Useful for warranty claims and purchase verification.
    **/

    function getRetailerInfo(
        uint256 productId  // product to query
    ) external view returns (
        address retailerAddress,  // retailer who sold the product
        uint32 saleDate,  // when product was sold (0 if not sold)
        bytes32 receiptIdHash  // hashed receipt identifier
    );
}