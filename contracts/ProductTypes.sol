pragma solidity ^0.8.28;


/**
This file lists everything about the PRODUCT in the supply chain system.

It includes the structure, possible errors, events (for record keeping),
and functions that is allowed to be called on the PRODUCT.
**/

struct Product {
    uint256 productId; // Used to index and identify product
    string status; // Used to indicate current status of product in supply chain
    address manufacturer; // Address of manufacturer
    uint256 manufactureTimestamp; // Time of manufacture, proof of authenticity
    address currentOwner; // Address of current owner
    bool isAuthentic; // Verifies if product is authentic
}