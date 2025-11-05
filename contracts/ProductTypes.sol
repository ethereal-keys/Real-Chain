pragma solidity ^0.8.28;


/**
This file lists everything about the PRODUCT in the supply chain system.

It includes the structure, possible errors, events (for record keeping),
and functions that is allowed to be called on the PRODUCT.
**/

enum ProductStatus {
    MANUFACTURED,
    QUALITY_CHECKED,
    IN_TRANSIT_TO_DISTRIBUTOR,
    IN_STORE,
    SOLD
}

struct Product {
    uint256 productId; // Used to index and identify product
    ProductStatus status; // Used to indicate current status of product in supply chain
    string ipfsHash; // Used for metadata stored off-chain (images, SKU, description)
    address manufacturer; // Address of manufacturer
    uint256 manufactureTimestamp; // Time of manufacture, proof of authenticity
    address currentOwner; // Address of current owner
    bool isAuthentic; // Verifies if product is authentic
}

mapping(uint256 => Product) public products;