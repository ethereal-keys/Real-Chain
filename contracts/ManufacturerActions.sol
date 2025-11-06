pragma solidity ^0.8.28;

import "./ProductTypes.sol";

/**
This file lists everything a MANUFACTURER can do in the supply chain system.

The manufacturer is responsible for creating products, quality checking them,
and shipping them to distributors.
**/

interface ManufacturerActions is ProductTypes {

    // ----------- Role ----------------
    // This is a special code used to check if someone is a manufacturer.
    function MANUFACTURER_ROLE() external view returns (bytes32);

    // -------- ERRORS -------------
    // This could help show why a transaction failed.

    error NotAuthorized();  // The caller doesn't have the permission
    error InvalidState();   // The product is not in the correct stage of action
    error NotCurrentHolder();   // The caller is not the current owner of the product
    error UnknownProduct(); // The product does not exist
    error ProductAlreadyExists(); // The product ID is already in use

    // ---------- EVENTS ---------------
    // These are like logs. They record what happened in blockchain

    // This event is triggered when a new product is created
    event ProductMinted(
        uint256 indexed productId,  // unique product ID for the product
        address indexed manufacturer, // factory address creating the product
        uint16 factoryId, // which factory location created it
        uint32 manufactureDate // timestamp when product was manufactured
    );

    // This event is triggered when a product passes quality control
    event QualityCheckPassed(
        uint256 indexed productId,  // product ID being quality checked
        address indexed inspector, // address of QC inspector
        uint32 checkDate // timestamp when QC passed
    );

    // This event is triggered when a manufacturer ships product to distributor
    event TransferredToDistributor(
        uint256 indexed productId,  // product ID being transferred
        address indexed manufacturer, // manufacturer sending the product
        address indexed distributor, // distributor receiving the product
        uint32 transferDate // timestamp of transfer
    );

    // This event logs when a manufacturer reports a defect in their product
    event ManufacturingDefectReported(
        uint256 indexed productId,  // product ID with defect
        address indexed manufacturer, // manufacturer reporting the defect
        bytes32 defectReportHash, // defect report details (hashed)
        uint32 reportedAt // timestamp when defect was reported
    );

    // --------------- Functions ----------------

    /**
    Function: mintProduct
    Called when a product comes off the production line.
    This creates a new product on the blockchain with status "MANUFACTURED".
    **/

    function mintProduct(
        uint256 productId, // unique product identifier
        uint16 factoryId, // factory location identifier
        string calldata ipfsHash, // IPFS hash for product metadata
        uint32 manufactureDate // timestamp when manufactured
    ) external;

    /**
    Function: markQualityPassed
    Called by QC inspector when a product passes quality control.
    Updates the product status to "QUALITY_CHECKED".
    **/

    function markQualityPassed(
        uint256 productId, // product being quality checked
        uint32 checkDate // timestamp of QC check
    ) external;

    /**
    Function: transferToDistributor
    Called when manufacturer ships a single product to a distributor.
    Updates ownership and status to "IN_TRANSIT_TO_DISTRIBUTOR".
    **/

    function transferToDistributor(
        uint256 productId, // product being transferred
        address distributor, // distributor receiving the product
        uint32 transferDate // timestamp of transfer
    ) external;

    /**
    Function: batchTransferToDistributor
    Called when manufacturer ships multiple products to a distributor.
    This is used for shipping pallets of products at once.
    **/

    function batchTransferToDistributor(
        uint256[] calldata productIds, // list of products being sent
        address distributor, // distributor receiving the products
        uint32 transferDate // timestamp of transfer
    ) external;

    /**
    Function: updateManufacturingDefect
    Called when a manufacturer discovers a defect in a product they made.
    This marks the product as not authentic.
    **/

    function updateManufacturingDefect(
        uint256 productId, // product with defect
        bytes32 defectReportHash, // defect report details (hashed)
        uint32 reportedAt // timestamp when reported
    ) external;
}
