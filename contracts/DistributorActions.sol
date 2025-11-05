pragma solidity ^0.8.28;

import "./ProductTypes.sol";

/**
This file lists everything a DISTRIBUTOR can do in the supply chain system.

The distributor is the link between the manufacturer and the retailer.

They can receive goods, ship them to retailers, update shipping progress,
and report if any products are damaged.
**/

interface DistributorActions is ProductTypes {

    // ----------- Role ----------------
    // This is a special code used to check if someone is a distributor.
    function DISTRIBUTOR_ROLE() external view returns (bytes32);

    // -------- ERRORS -------------
    // This could help show why a transaction failed.

    error NotAuthorized();  // The Caller doesnt have the permission
    error InvalidState();   // The product is not in the correct stage of action
    error NotCurrentHolder();   // The caller is not the current owner of the product
    error UnknownProduct(); // The product does not exist

    // ---------- EVENTS ---------------
    // These are like logs. They record what happened in blockchain


    // This event is triggered when a manufacturer sends a product to a distributor.
    event ShippedToDistributor(
        uint256 indexed productId,  // unique product id for the product being shipped
        address indexed fromFactoryOrOwner, // factory owner sending the product
        address indexed distributor,    // distributor  receiving the product
        uint32 shipDate // timestamp of shipment
    );


    // This event is triggered when a distributor prepares a shipment to a retailer.
    event RetailShipmentDeclared(
        uint256 indexed productId,  // product Id being shipped
        address indexed distributor,    // distributor sending the product
        address indexed retailer,   // retailer receiving the product
        uint32 shipDate,    // timestamp when shipment was dispatched
        bytes32 waybillHash // off-chain shipping details (hashed)
    );

    // This event logs any shipping updates — for example, when goods leave a warehouse
    // or reach a delivery hub.

    event ShippingStatusUpdated(
        uint256 indexed productId,  // product Id being tracked
        bytes32 trackingHash,   // tracking information (hashed pointer)
        uint32 updatedAt    // timestamp when update was recorded
    );


    // This event logs when a distributor reports a damaged product.

    event DamagedReported(
        uint256 indexed productId,  // product Id of damaged product
        bytes32 reportHash, // damage report (photo, document, etc..) (hashed)
        uint32 reportedAt   // timestamp when damage was reported
    );

    // --------------- Functions ----------------


    function batchTransferToDistributor(
        uint256[] calldata productIds,  // list of products being sent
        address distributor,    // distributor receving it
        uint32 shipDate // timestamp of shipment
    ) external;

    function createRetailShipment(
        uint256[] calldata productIds,
        address retailer,   // retailer receiving the shipment
        uint32 shipDate,
        bytes32 waybillHash
    ) external;

    function updateShippingStatus(
        uint256[] calldata productIds,
        bytes32 trackingHash,
        uint32 updatedAt
    ) external;

    function reportDamaged(
        uint256 productId,
        bytes32 reportHash,
        uint32 reportedAt
    ) external;

}