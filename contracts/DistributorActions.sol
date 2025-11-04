pragma solidity ^0.8.28;

import "./ProductTypes.sol";

/**
This file lists everything a DISTRIBUTOR can do in the supply chain system.

It includes the role name, possible errors, events (for record keeping),
and functions that a distributor is allowed to call.
**/

interface DistributorActions is ProductTypes {

    // ----------- Role ----------------
    // This is a unique code to check if someone is Distributor.
    function DISTRIBUTOR_ROLE() external view returns (bytes32);

    // -------- ERRORS -------------
    // This could help show why a transaction failed.

    error NotAuthorized();  // The Caller doesnt have the permission
    error InvalidState();   // The product is not in the correct stage of action
    error NotCurrentHolder();   // The caller is not the current owner of the product
    error UnknownProduct(); // The product does not exist

    event ShippedToDistributor(
        uint256 indexed productId,
        address indexed fromFactoryOrOwner,
        address indexed distributor,
        uint32 shipDate
    );

    event RetailShipmentDeclared(
        uint256 indexed productId,
        address indexed distributor,
        address indexed retailer,
        uint32 shipDate,
        bytes32 waybillHash
    );

    event ShippingStatusUpdated(
        uint256 indexed productId,
        bytes32 trackingHash,
        uint32 updatedAt
    );

    event DamagedReported(
        uint256 indexed productId,
        bytes32 reportHash,
        uint32 reportedAt
    );

    function batchTransferToDistributor(
        uint256[] calldata productIds,
        address distributor,
        uint32 shipDate
    ) external;

    function createRetailShipment(
        uint256[] calldata productIds,
        address retailer,
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