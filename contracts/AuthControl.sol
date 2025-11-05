// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ProductTypes.sol"; // exposes contract SupplyChain with Product + ProductStatus

/**
 * Auth/Admin contract wired to your shared product types.
 * - Uses SupplyChain.Product and SupplyChain.ProductStatus verbatim.
 * - Roles: ADMIN_ROLE, MANUFACTURER_ROLE, DISTRIBUTOR_ROLE, RETAILER_ROLE, QC_ROLE
 * - Emergency controls: pause/unpause, recall() -> sets isAuthentic = false
 */
contract MerchandiseAuth is AccessControl, Pausable {
    // ===== Roles (match your names) =====
    bytes32 public constant ADMIN_ROLE        = keccak256("ADMIN_ROLE");
    bytes32 public constant MANUFACTURER_ROLE = keccak256("MANUFACTURER_ROLE");
    bytes32 public constant DISTRIBUTOR_ROLE  = keccak256("DISTRIBUTOR_ROLE");
    bytes32 public constant RETAILER_ROLE     = keccak256("RETAILER_ROLE");
    bytes32 public constant QC_ROLE           = keccak256("QC_ROLE");

    // ===== Storage using your types =====
    // productId => Product
    mapping(uint256 => SupplyChain.Product) private products;
    mapping(uint256 => bool) private _exists; // existence flag since Product has no 'exists' field

    // ===== Events =====
    event PartnerAdded(bytes32 indexed role, address indexed account);
    event PartnerRemoved(bytes32 indexed role, address indexed account);

    event ProductMinted(uint256 indexed productId, address indexed manufacturer, string ipfsHash);
    event MarkedQC(uint256 indexed productId, address indexed inspector);
    event BatchTransfer(uint256[] productIds, address indexed from, address indexed to);
    event ReceivedAtStore(uint256 indexed productId, address indexed retailer);
    event MarkedSold(uint256 indexed productId, bytes32 receiptIdHash, address indexed retailer);
    event Recalled(uint256 indexed productId, address indexed admin);

    constructor(address admin) {
        // Set OZ admin + app-level ADMIN_ROLE
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
    }

    // ========= Admin (RBAC management) =========

    function addManufacturer(address account) external onlyRole(ADMIN_ROLE) {
        _grantRole(MANUFACTURER_ROLE, account);
        emit PartnerAdded(MANUFACTURER_ROLE, account);
    }

    function removeManufacturer(address account) external onlyRole(ADMIN_ROLE) {
        _revokeRole(MANUFACTURER_ROLE, account);
        emit PartnerRemoved(MANUFACTURER_ROLE, account);
    }

    function addDistributor(address account) external onlyRole(ADMIN_ROLE) {
        _grantRole(DISTRIBUTOR_ROLE, account);
        emit PartnerAdded(DISTRIBUTOR_ROLE, account);
    }

    function removeDistributor(address account) external onlyRole(ADMIN_ROLE) {
        _revokeRole(DISTRIBUTOR_ROLE, account);
        emit PartnerRemoved(DISTRIBUTOR_ROLE, account);
    }

    function addRetailer(address account) external onlyRole(ADMIN_ROLE) {
        _grantRole(RETAILER_ROLE, account);
        emit PartnerAdded(RETAILER_ROLE, account);
    }

    function removeRetailer(address account) external onlyRole(ADMIN_ROLE) {
        _revokeRole(RETAILER_ROLE, account);
        emit PartnerRemoved(RETAILER_ROLE, account);
    }

    function addInspector(address account) external onlyRole(ADMIN_ROLE) {
        _grantRole(QC_ROLE, account);
        emit PartnerAdded(QC_ROLE, account);
    }

    function removeInspector(address account) external onlyRole(ADMIN_ROLE) {
        _revokeRole(QC_ROLE, account);
        emit PartnerRemoved(QC_ROLE, account);
    }

    // Emergency controls
    function pause() external onlyRole(ADMIN_ROLE) { _pause(); }
    function unpause() external onlyRole(ADMIN_ROLE) { _unpause(); }

    // ========= Lifecycle (auth-gated) =========

    /// Manufacturer mints a product with its IPFS metadata
    function mint(uint256 productId, string calldata ipfsHash)
        external
        whenNotPaused
        onlyRole(MANUFACTURER_ROLE)
    {
        require(!_exists[productId], "Product already exists");

        SupplyChain.Product storage p = products[productId];
        p.productId            = productId;
        p.status               = SupplyChain.ProductStatus.MANUFACTURED;
        p.ipfsHash             = ipfsHash;
        p.manufacturer         = msg.sender;
        p.manufactureTimestamp = block.timestamp;
        p.currentOwner         = msg.sender;
        p.isAuthentic          = true;

        _exists[productId] = true;
        emit ProductMinted(productId, msg.sender, ipfsHash);
    }

    /// QC pass (performed by QC_ROLE)
    function markQC(uint256 productId)
        external
        whenNotPaused
        onlyRole(QC_ROLE)
    {
        _requireKnown(productId);
        SupplyChain.Product storage p = products[productId];
        require(p.status == SupplyChain.ProductStatus.MANUFACTURED, "Bad status");
        p.status = SupplyChain.ProductStatus.QUALITY_CHECKED;
        emit MarkedQC(productId, msg.sender);
    }

    /// Distributor custody handoff (batch)
    function batchTransfer(uint256[] calldata productIds, address to)
        external
        whenNotPaused
        onlyRole(DISTRIBUTOR_ROLE)
    {
        require(to != address(0), "to=0");
        for (uint256 i = 0; i < productIds.length; i++) {
            uint256 id = productIds[i];
            _requireKnown(id);
            SupplyChain.Product storage p = products[id];

            // Optional strictness:
            // require(p.currentOwner == msg.sender, "Not custodian");

            p.currentOwner = to;
            p.status = SupplyChain.ProductStatus.IN_TRANSIT_TO_DISTRIBUTOR;
        }
        emit BatchTransfer(productIds, msg.sender, to);
    }

    /// Retailer receives into store
    function receiveAtStore(uint256 productId)
        external
        whenNotPaused
        onlyRole(RETAILER_ROLE)
    {
        _requireKnown(productId);
        SupplyChain.Product storage p = products[productId];
        p.currentOwner = msg.sender;
        p.status = SupplyChain.ProductStatus.IN_STORE;
        emit ReceivedAtStore(productId, msg.sender);
    }

    /// Mark sold (customer identity off-chain; include an off-chain receipt hash)
    function markSold(uint256 productId, bytes32 receiptIdHash)
        external
        whenNotPaused
        onlyRole(RETAILER_ROLE)
    {
        _requireKnown(productId);
        SupplyChain.Product storage p = products[productId];
        require(p.currentOwner == msg.sender, "Not store owner");
        p.currentOwner = address(0); // end of on-chain custody
        p.status = SupplyChain.ProductStatus.SOLD;
        emit MarkedSold(productId, receiptIdHash, msg.sender);
    }

    /// Admin recall — marks product as not authentic (status unchanged)
    function recall(uint256 productId)
        external
        onlyRole(ADMIN_ROLE)
    {
        _requireKnown(productId);
        products[productId].isAuthentic = false;
        emit Recalled(productId, msg.sender);
    }

    // ========= Views =========

    function getProduct(uint256 productId)
        external
        view
        returns (SupplyChain.Product memory)
    {
        _requireKnown(productId);
        return products[productId];
    }

    function exists(uint256 productId) external view returns (bool) {
        return _exists[productId];
    }

    // ========= Internal helpers =========
    function _requireKnown(uint256 productId) internal view {
        require(_exists[productId], "Unknown product");
    }
}
