// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title SupplyChain
 * @dev Disney Supply Chain Tracking Smart Contract
 * @notice This contract tracks products from manufacture to sale
 * 
 * TEAM NOTES:
 * - Complete all TODO sections
 * - Add proper error handling
 * - Optimize for gas where possible
 * - Test each function thoroughly
 */
contract SupplyChain {
    
    // ========================================
    // STATE VARIABLES
    // ========================================
    
    /**
     * TODO 1: Define the ProductStatus enum
     * Should include: MANUFACTURED, QUALITY_CHECKED, WITH_DISTRIBUTOR, WITH_RETAILER, SOLD
     */
    enum ProductStatus {
        // TODO: Add status values here
    }
    
    /**
     * TODO 2: Define the Product struct
     * Should include:
     * - uint256 productId
     * - ProductStatus status
     * - address manufacturer
     * - address currentOwner
     * - uint256 manufactureTimestamp
     * - string ipfsHash (for metadata)
     * - bool isAuthentic
     * - uint256 scanCount
     */
    struct Product {
        // TODO: Add struct fields here
    }
    
    /**
     * TODO 3: Define role constants using bytes32
     * Hint: Use keccak256("ROLE_NAME") for each role
     */
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    // TODO: Add MANUFACTURER_ROLE
    // TODO: Add DISTRIBUTOR_ROLE  
    // TODO: Add RETAILER_ROLE
    // TODO: Add QC_INSPECTOR_ROLE
    
    /**
     * TODO 4: Define mappings
     */
    // Mapping from productId to Product
    mapping(uint256 => Product) public products;
    
    // TODO: Add mapping for product history (productId => array of addresses)
    
    // TODO: Add mapping for user roles (address => role => bool)
    
    // TODO: Add mapping to track if a productId exists (for validation)
    
    // ========================================
    // EVENTS
    // ========================================
    
    /**
     * TODO 5: Define events
     * Think about what actions need to be logged for transparency
     */
    event ProductCreated(
        uint256 indexed productId, 
        address indexed manufacturer,
        uint256 timestamp
    );
    
    // TODO: Add ProductStatusUpdated event
    // TODO: Add ProductTransferred event
    // TODO: Add ProductScanned event
    // TODO: Add RoleGranted event
    // TODO: Add RoleRevoked event
    
    // ========================================
    // MODIFIERS
    // ========================================
    
    /**
     * TODO 6: Implement role-based access control modifier
     * Should check if msg.sender has the required role
     */
    modifier onlyRole(bytes32 role) {
        // TODO: Implement role check
        // Hint: require(hasRole[msg.sender][role], "Unauthorized");
        _;
    }
    
    /**
     * TODO 7: Implement product exists modifier
     * Should check if product ID exists in the system
     */
    modifier productExists(uint256 _productId) {
        // TODO: Implement existence check
        _;
    }
    
    /**
     * TODO 8: Implement ownership modifier
     * Should check if msg.sender owns the product
     */
    modifier onlyProductOwner(uint256 _productId) {
        // TODO: Implement ownership check
        _;
    }
    
    // ========================================
    // CONSTRUCTOR
    // ========================================
    
    /**
     * TODO 9: Implement constructor
     * Should set up the deployer as admin
     */
    constructor() {
        // TODO: Grant ADMIN_ROLE to msg.sender
        // Hint: hasRole[msg.sender][ADMIN_ROLE] = true;
    }
    
    // ========================================
    // CORE FUNCTIONS
    // ========================================
    
    /**
     * TODO 10: Implement createProduct function
     * @param _productId Unique identifier for the product
     * @param _ipfsHash IPFS hash containing product metadata
     * 
     * Requirements:
     * - Only MANUFACTURER_ROLE can call
     * - Product ID must not exist already
     * - Set initial status to MANUFACTURED
     * - Set manufacturer and currentOwner to msg.sender
     * - Set isAuthentic to true
     * - Initialize scanCount to 0
     * - Emit ProductCreated event
     */
    function createProduct(
        uint256 _productId,
        string memory _ipfsHash
    ) external onlyRole(MANUFACTURER_ROLE) {
        // TODO: Check product doesn't exist
        
        // TODO: Create new Product struct
        
        // TODO: Store product in mapping
        
        // TODO: Add manufacturer to product history
        
        // TODO: Mark product as existing
        
        // TODO: Emit ProductCreated event
    }
    
    /**
     * TODO 11: Implement qualityCheck function
     * @param _productId Product to quality check
     * 
     * Requirements:
     * - Only QC_INSPECTOR_ROLE can call
     * - Product must exist
     * - Status must be MANUFACTURED
     * - Update status to QUALITY_CHECKED
     * - Emit ProductStatusUpdated event
     */
    function qualityCheck(uint256 _productId) 
        external 
        onlyRole(QC_INSPECTOR_ROLE)
        productExists(_productId)
    {
        // TODO: Verify current status is MANUFACTURED
        
        // TODO: Update product status
        
        // TODO: Emit event
    }
    
    /**
     * TODO 12: Implement transferToDistributor function
     * @param _productId Product to transfer
     * @param _distributor Address of the distributor
     * 
     * Requirements:
     * - Only MANUFACTURER_ROLE can call
     * - Must be product owner
     * - Product must be QUALITY_CHECKED
     * - Distributor must have DISTRIBUTOR_ROLE
     * - Update currentOwner and status
     * - Add to product history
     * - Emit ProductTransferred event
     */
    function transferToDistributor(uint256 _productId, address _distributor)
        external
        onlyRole(MANUFACTURER_ROLE)
        productExists(_productId)
        onlyProductOwner(_productId)
    {
        // TODO: Verify distributor has correct role
        
        // TODO: Verify product status is QUALITY_CHECKED
        
        // TODO: Update currentOwner
        
        // TODO: Update status to WITH_DISTRIBUTOR
        
        // TODO: Add distributor to product history
        
        // TODO: Emit ProductTransferred event
    }
    
    /**
     * TODO 13: Implement transferToRetailer function
     * @param _productId Product to transfer
     * @param _retailer Address of the retailer
     * 
     * Requirements:
     * - Only DISTRIBUTOR_ROLE can call
     * - Must be product owner
     * - Product must be WITH_DISTRIBUTOR
     * - Retailer must have RETAILER_ROLE
     * - Update currentOwner and status
     * - Add to product history
     * - Emit ProductTransferred event
     */
    function transferToRetailer(uint256 _productId, address _retailer)
        external
        onlyRole(DISTRIBUTOR_ROLE)
        productExists(_productId)
        onlyProductOwner(_productId)
    {
        // TODO: Implement transfer logic (similar to transferToDistributor)
    }
    
    /**
     * TODO 14: Implement markAsSold function
     * @param _productId Product that was sold
     * 
     * Requirements:
     * - Only RETAILER_ROLE can call
     * - Must be product owner
     * - Product must be WITH_RETAILER
     * - Update status to SOLD
     * - Set currentOwner to address(0)
     * - Emit ProductStatusUpdated event
     */
    function markAsSold(uint256 _productId)
        external
        onlyRole(RETAILER_ROLE)
        productExists(_productId)
        onlyProductOwner(_productId)
    {
        // TODO: Implement sale logic
    }
    
    // ========================================
    // VERIFICATION FUNCTIONS
    // ========================================
    
    /**
     * TODO 15: Implement verifyProduct function
     * @param _productId Product to verify
     * @return isAuthentic Whether product is authentic
     * @return status Current product status
     * @return manufacturer Original manufacturer address
     * @return currentOwner Current owner address
     * 
     * Requirements:
     * - Public function (anyone can verify)
     * - Product must exist
     * - Return product details
     * - Increment scan count
     */
    function verifyProduct(uint256 _productId)
        external
        view
        productExists(_productId)
        returns (
            bool isAuthentic,
            ProductStatus status,
            address manufacturer,
            address currentOwner
        )
    {
        // TODO: Get product from mapping
        
        // TODO: Return product details
    }
    
    /**
     * TODO 16: Implement scanProduct function
     * @param _productId Product that was scanned
     * 
     * Requirements:
     * - Public function (anyone can scan)
     * - Increment scanCount
     * - Emit ProductScanned event
     */
    function scanProduct(uint256 _productId) 
        external 
        productExists(_productId)
    {
        // TODO: Increment scan count
        
        // TODO: Emit ProductScanned event
    }
    
    /**
     * TODO 17: Implement getProductHistory function
     * @param _productId Product to get history for
     * @return addresses Array of addresses in the supply chain
     * 
     * Requirements:
     * - Return array of all addresses that owned the product
     */
    function getProductHistory(uint256 _productId)
        external
        view
        productExists(_productId)
        returns (address[] memory)
    {
        // TODO: Return product history array
    }
    
    // ========================================
    // ROLE MANAGEMENT FUNCTIONS
    // ========================================
    
    /**
     * TODO 18: Implement grantRole function
     * @param _account Address to grant role to
     * @param _role Role to grant
     * 
     * Requirements:
     * - Only ADMIN_ROLE can call
     * - Update hasRole mapping
     * - Emit RoleGranted event
     */
    function grantRole(address _account, bytes32 _role)
        external
        onlyRole(ADMIN_ROLE)
    {
        // TODO: Grant role to account
        
        // TODO: Emit RoleGranted event
    }
    
    /**
     * TODO 19: Implement revokeRole function
     * @param _account Address to revoke role from
     * @param _role Role to revoke
     * 
     * Requirements:
     * - Only ADMIN_ROLE can call
     * - Update hasRole mapping
     * - Emit RoleRevoked event
     */
    function revokeRole(address _account, bytes32 _role)
        external
        onlyRole(ADMIN_ROLE)
    {
        // TODO: Revoke role from account
        
        // TODO: Emit RoleRevoked event
    }
    
    /**
     * TODO 20: Implement hasRole function
     * @param _account Address to check
     * @param _role Role to check for
     * @return bool Whether account has role
     */
    function hasRole(address _account, bytes32 _role)
        public
        view
        returns (bool)
    {
        // TODO: Return whether account has role
    }
    
    // ========================================
    // BATCH OPERATIONS (OPTIONAL - BONUS)
    // ========================================
    
    /**
     * TODO BONUS 1: Implement batchCreateProducts
     * Create multiple products in one transaction to save gas
     */
    function batchCreateProducts(
        uint256[] memory _productIds,
        string[] memory _ipfsHashes
    ) external onlyRole(MANUFACTURER_ROLE) {
        // TODO: Loop through arrays and create each product
        // Hint: Check array lengths match first
    }
    
    /**
     * TODO BONUS 2: Implement batchTransfer
     * Transfer multiple products to the same recipient
     */
    function batchTransfer(
        uint256[] memory _productIds,
        address _recipient
    ) external {
        // TODO: Implement batch transfer logic
    }
    
    // ========================================
    // HELPER FUNCTIONS
    // ========================================
    
    /**
     * TODO 21: Implement getProduct function
     * @param _productId Product ID to query
     * @return Product struct
     */
    function getProduct(uint256 _productId)
        external
        view
        productExists(_productId)
        returns (Product memory)
    {
        // TODO: Return product from mapping
    }
    
    /**
     * TODO 22: Implement getStatusString function
     * @param _status Status enum value
     * @return string Human-readable status
     * 
     * Helper function to convert enum to string for frontend
     */
    function getStatusString(ProductStatus _status)
        external
        pure
        returns (string memory)
    {
        // TODO: Convert enum to string
        // Hint: Use if/else statements
        // Example: if (_status == ProductStatus.MANUFACTURED) return "MANUFACTURED";
    }
    
    // ========================================
    // EMERGENCY FUNCTIONS (OPTIONAL)
    // ========================================
    
    /**
     * TODO BONUS 3: Implement recallProduct function
     * Mark a product as not authentic (for recalls)
     * Only ADMIN_ROLE should be able to do this
     */
    function recallProduct(uint256 _productId)
        external
        onlyRole(ADMIN_ROLE)
        productExists(_productId)
    {
        // TODO: Set isAuthentic to false
        // TODO: Emit appropriate event
    }
}