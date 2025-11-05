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

    function addManufacturer(address account) external onlyRole(ADMIN_ROLE);

    function removeManufacturer(address account) external onlyRole(ADMIN_ROLE);

    function addDistributor(address account) external onlyRole(ADMIN_ROLE);

    function removeDistributor(address account) external onlyRole(ADMIN_ROLE);

    function addRetailer(address account) external onlyRole(ADMIN_ROLE);

    function removeRetailer(address account) external onlyRole(ADMIN_ROLE);

    function addInspector(address account) external onlyRole(ADMIN_ROLE);

    function removeInspector(address account) external onlyRole(ADMIN_ROLE);

    // Emergency controls
    function pause() external onlyRole(ADMIN_ROLE) { _pause(); }
    function unpause() external onlyRole(ADMIN_ROLE) { _unpause(); }

    // ========= Lifecycle (auth-gated) =========

    /// Manufacturer mints a product with its IPFS metadata
    function mint(uint256 productId, string calldata ipfsHash)
        external
        whenNotPaused
        onlyRole(MANUFACTURER_ROLE);

    /// QC pass (performed by QC_ROLE)
    function markQC(uint256 productId)
        external
        whenNotPaused
        onlyRole(QC_ROLE);

    /// Distributor custody handoff (batch)
    function batchTransfer(uint256[] calldata productIds, address to)
        external
        whenNotPaused
        onlyRole(DISTRIBUTOR_ROLE);

    /// Retailer receives into store
    function receiveAtStore(uint256 productId)
        external
        whenNotPaused
        onlyRole(RETAILER_ROLE);

    /// Mark sold (customer identity off-chain; include an off-chain receipt hash)
    function markSold(uint256 productId, bytes32 receiptIdHash)
        external
        whenNotPaused
        onlyRole(RETAILER_ROLE);

    /// Admin recall — marks product as not authentic (status unchanged)
    function recall(uint256 productId)
        external
        onlyRole(ADMIN_ROLE);

    // ========= Views =========

    function getProduct(uint256 productId)
        external
        view
        returns (SupplyChain.Product memory);

    function exists(uint256 productId) external view returns (bool);
}
