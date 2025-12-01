// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title SupplyChainManufacturer
 * @dev Optimized implementation to avoid stack too deep errors
 */
contract SupplyChainManufacturer is AccessControl, Pausable, ReentrancyGuard {
    
    // ===== Product Structure and Enums =====
    enum ProductStatus {
        MANUFACTURED,
        QUALITY_CHECKED,
        IN_TRANSIT_TO_DISTRIBUTOR,
        WITH_DISTRIBUTOR,
        IN_TRANSIT_TO_RETAILER,
        IN_STORE,
        SOLD,
        RETURNED
    }

    // Split the product struct into core and extended data
    struct ProductCore {
        uint256 productId;
        ProductStatus status;
        address manufacturer;
        address currentOwner;
        bool isAuthentic;
        uint16 factoryId;
    }

    struct ProductExtended {
        string ipfsHash;
        uint32 manufactureTimestamp;
        uint32 qualityCheckDate;
        uint32 saleDate;
        uint32 scanCount;
        uint32 transferCount;
    }

    struct ProductChain {
        address distributor;
        address retailer;
        bytes32 receiptIdHash;
    }

    // ===== Role Definitions =====
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MANUFACTURER_ROLE = keccak256("MANUFACTURER_ROLE");
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");
    bytes32 public constant RETAILER_ROLE = keccak256("RETAILER_ROLE");
    bytes32 public constant QC_ROLE = keccak256("QC_ROLE");

    // ===== Storage =====
    mapping(uint256 => ProductCore) public productCore;
    mapping(uint256 => ProductExtended) public productExtended;
    mapping(uint256 => ProductChain) public productChain;
    mapping(uint256 => bool) public exists;
    
    mapping(address => uint256[]) public manufacturerProducts;
    mapping(address => uint256[]) public distributorProducts;
    
    // Track authorized manufacturers and their factory IDs
    mapping(address => bool) public authorizedManufacturers;
    mapping(address => uint16[]) public manufacturerFactories;

    // ===== Events =====
    event ProductMinted(
        uint256 indexed productId,
        address indexed manufacturer,
        uint16 factoryId,
        uint32 manufactureDate
    );

    event QualityCheckPassed(
        uint256 indexed productId,
        address indexed inspector,
        uint32 checkDate
    );

    event TransferredToDistributor(
        uint256 indexed productId,
        address indexed from,
        address indexed to,
        uint32 transferDate
    );

    event ManufacturingDefectReported(
        uint256 indexed productId,
        address indexed manufacturer,
        bytes32 defectReportHash
    );

    event BatchTransfer(
        uint256[] productIds,
        address indexed from,
        address indexed to
    );

    event PartnerAdded(bytes32 indexed role, address indexed account);
    event PartnerRemoved(bytes32 indexed role, address indexed account);

    // ===== Constructor =====
    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
    }

    // ===== Modifiers =====
    modifier productExists(uint256 productId) {
        require(exists[productId], "Product does not exist");
        _;
    }

    modifier productNotExists(uint256 productId) {
        require(!exists[productId], "Product already exists");
        _;
    }

    // ===== Admin Functions =====
    
    function addManufacturer(address account, uint16[] calldata factoryIds) 
        external 
        onlyRole(ADMIN_ROLE) 
    {
        require(account != address(0), "Invalid address");
        grantRole(MANUFACTURER_ROLE, account);
        authorizedManufacturers[account] = true;
        manufacturerFactories[account] = factoryIds;
        emit PartnerAdded(MANUFACTURER_ROLE, account);
    }

    function removeManufacturer(address account) 
        external 
        onlyRole(ADMIN_ROLE) 
    {
        revokeRole(MANUFACTURER_ROLE, account);
        authorizedManufacturers[account] = false;
        delete manufacturerFactories[account];
        emit PartnerRemoved(MANUFACTURER_ROLE, account);
    }

    function addDistributor(address account) 
        external 
        onlyRole(ADMIN_ROLE) 
    {
        require(account != address(0), "Invalid address");
        grantRole(DISTRIBUTOR_ROLE, account);
        emit PartnerAdded(DISTRIBUTOR_ROLE, account);
    }

    function addInspector(address account) 
        external 
        onlyRole(ADMIN_ROLE) 
    {
        require(account != address(0), "Invalid address");
        grantRole(QC_ROLE, account);
        emit PartnerAdded(QC_ROLE, account);
    }

    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    // ===== Manufacturer Functions =====
    
    function mintProduct(
        uint256 productId,
        uint16 factoryId,
        string calldata ipfsHash,
        uint32 manufactureDate
    ) 
        external 
        whenNotPaused 
        onlyRole(MANUFACTURER_ROLE)
        productNotExists(productId)
        nonReentrant
    {
        // Validate factory ID
        require(_isValidFactory(msg.sender, factoryId), "Invalid factory ID");

        // Create product core data
        ProductCore storage core = productCore[productId];
        core.productId = productId;
        core.status = ProductStatus.MANUFACTURED;
        core.manufacturer = msg.sender;
        core.currentOwner = msg.sender;
        core.isAuthentic = true;
        core.factoryId = factoryId;

        // Create extended data
        ProductExtended storage extended = productExtended[productId];
        extended.ipfsHash = ipfsHash;
        extended.manufactureTimestamp = manufactureDate;
        extended.scanCount = 0;
        extended.transferCount = 0;

        exists[productId] = true;
        manufacturerProducts[msg.sender].push(productId);

        emit ProductMinted(productId, msg.sender, factoryId, manufactureDate);
    }

    function markQualityPassed(uint256 productId, uint32 checkDate) 
        external 
        whenNotPaused 
        onlyRole(QC_ROLE)
        productExists(productId)
        nonReentrant
    {
        ProductCore storage core = productCore[productId];
        require(core.status == ProductStatus.MANUFACTURED, "Invalid state");
        
        core.status = ProductStatus.QUALITY_CHECKED;
        productExtended[productId].qualityCheckDate = checkDate;

        emit QualityCheckPassed(productId, msg.sender, checkDate);
    }

    function transferToDistributor(
        uint256 productId,
        address distributor,
        uint32 transferDate
    ) 
        external 
        whenNotPaused 
        onlyRole(MANUFACTURER_ROLE)
        productExists(productId)
        nonReentrant
    {
        require(hasRole(DISTRIBUTOR_ROLE, distributor), "Not authorized distributor");
        
        ProductCore storage core = productCore[productId];
        require(core.currentOwner == msg.sender, "Not owner");
        require(core.status == ProductStatus.QUALITY_CHECKED, "Must pass QC first");

        core.status = ProductStatus.IN_TRANSIT_TO_DISTRIBUTOR;
        core.currentOwner = distributor;
        
        productChain[productId].distributor = distributor;
        productExtended[productId].transferCount++;
        
        distributorProducts[distributor].push(productId);

        emit TransferredToDistributor(productId, msg.sender, distributor, transferDate);
    }

    function batchTransferToDistributor(
        uint256[] calldata productIds,
        address distributor,
        uint32 transferDate
    ) 
        external 
        whenNotPaused 
        onlyRole(MANUFACTURER_ROLE)
        nonReentrant
    {
        require(hasRole(DISTRIBUTOR_ROLE, distributor), "Not authorized distributor");
        
        for (uint i = 0; i < productIds.length; i++) {
            uint256 pid = productIds[i];
            if (!exists[pid]) continue;
            
            ProductCore storage core = productCore[pid];
            if (core.currentOwner != msg.sender || 
                core.status != ProductStatus.QUALITY_CHECKED) {
                continue;
            }

            core.status = ProductStatus.IN_TRANSIT_TO_DISTRIBUTOR;
            core.currentOwner = distributor;
            productChain[pid].distributor = distributor;
            productExtended[pid].transferCount++;
            distributorProducts[distributor].push(pid);
        }

        emit BatchTransfer(productIds, msg.sender, distributor);
    }

    function updateManufacturingDefect(
        uint256 productId,
        bytes32 defectReportHash
    ) 
        external 
        whenNotPaused 
        onlyRole(MANUFACTURER_ROLE)
        productExists(productId)
        nonReentrant
    {
        ProductCore storage core = productCore[productId];
        require(core.manufacturer == msg.sender, "Not original manufacturer");
        
        core.isAuthentic = false;
        emit ManufacturingDefectReported(productId, msg.sender, defectReportHash);
    }

    // ===== View Functions =====
    
    function getProductCore(uint256 productId) 
        external 
        view 
        productExists(productId)
        returns (
            uint256 id,
            ProductStatus status,
            address manufacturer,
            address currentOwner,
            bool isAuthentic,
            uint16 factoryId
        ) 
    {
        ProductCore memory core = productCore[productId];
        return (
            core.productId,
            core.status,
            core.manufacturer,
            core.currentOwner,
            core.isAuthentic,
            core.factoryId
        );
    }

    function getProductExtended(uint256 productId)
        external
        view
        productExists(productId)
        returns (
            string memory ipfsHash,
            uint32 manufactureTimestamp,
            uint32 qualityCheckDate,
            uint32 saleDate,
            uint32 scanCount,
            uint32 transferCount
        )
    {
        ProductExtended memory extended = productExtended[productId];
        return (
            extended.ipfsHash,
            extended.manufactureTimestamp,
            extended.qualityCheckDate,
            extended.saleDate,
            extended.scanCount,
            extended.transferCount
        );
    }

    function getProductChain(uint256 productId)
        external
        view
        productExists(productId)
        returns (
            address distributor,
            address retailer,
            bytes32 receiptIdHash
        )
    {
        ProductChain memory chain = productChain[productId];
        return (chain.distributor, chain.retailer, chain.receiptIdHash);
    }

    function verifyAuthenticity(uint256 productId) 
        external 
        productExists(productId)
        returns (
            bool isAuthentic,
            ProductStatus currentStatus,
            address manufacturer,
            uint32 manufactureDate
        ) 
    {
        productExtended[productId].scanCount++;
        
        ProductCore memory core = productCore[productId];
        return (
            core.isAuthentic,
            core.status,
            core.manufacturer,
            productExtended[productId].manufactureTimestamp
        );
    }

    function getManufacturerProducts(address manufacturer) 
        external 
        view 
        returns (uint256[] memory) 
    {
        return manufacturerProducts[manufacturer];
    }

    // ===== Internal Helper Functions =====
    
    function _isValidFactory(address manufacturer, uint16 factoryId) 
        internal 
        view 
        returns (bool) 
    {
        uint16[] memory factories = manufacturerFactories[manufacturer];
        for (uint i = 0; i < factories.length; i++) {
            if (factories[i] == factoryId) {
                return true;
            }
        }
        return false;
    }
}