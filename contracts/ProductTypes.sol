// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
This file lists everything about the PRODUCT in the supply chain system.

It includes the structure, possible errors, events (for record keeping),
and functions that is allowed to be called on the PRODUCT.
**/

contract SupplyChain {

    // --------------- Product Structure and Enum ----------------

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

    // --------------- Role Management ----------------

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MANUFACTURER_ROLE = keccak256("MANUFACTURER_ROLE");
    bytes32 public constant DISTRIBUTOR_ROLE  = keccak256("DISTRIBUTOR_ROLE");
    bytes32 public constant RETAILER_ROLE     = keccak256("RETAILER_ROLE");
    bytes32 public constant QC_ROLE           = keccak256("QC_ROLE");

    mapping(address => mapping(bytes32 => bool)) public hasRole; // Checks if the address has that role

    // --------------- Constructor ----------------

    constructor() {
        // Deployer is admin
        hasRole[msg.sender][ADMIN_ROLE] = true;

        // Map roles to respective wallet addresses
        hasRole[0xManufacturerWalletAddress][MANUFACTURER_ROLE] = true;
        hasRole[0xDistributorWalletAddress][DISTRIBUTOR_ROLE] = true;
        hasRole[0xRetailerWalletAddress][RETAILER_ROLE] = true;
        hasRole[0xQcInspectorWalletAddress][QC_ROLE] = true;
    }

    // --------------- Modifiers ----------------

    modifier onlyRole(bytes32 role) {
        require(hasRole[msg.sender][role], "Unauthorized: Incorrect Role"); // Used to enforce role-based access control
        _;
    }


    // --------------- Functions ----------------

    function grantRole(address _account, bytes32 _role)
        external
        onlyRole(ADMIN_ROLE)
    {
        /**
            Function: grantRole
            Used by the admin when assigning role to a wallet.
        **/
    }


    function revokeRole(address _account, bytes32 _role)
        external
        onlyRole(ADMIN_ROLE)
    {
        /**
            Function: revokeRole
            Used by the admin to revoke role from a wallet.
        **/
    }


    function hasRoleAssigned(address _account, bytes32 _role)
        external
        view
        returns (bool)
    {
        /**
            Function: hasRoleAssigned
            Used by the admin to verify if role is assigned to an account.
            Returns true if that account has that role
        **/
        return hasRole[_account][_role];
    }
}

