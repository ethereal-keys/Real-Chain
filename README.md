# Real-Chain
Tackling Counterfeiting in Licensed Entertainment Merchandise Using Blockchain

# Blockchain Product Authentication System

## Overview

A blockchain-based product authentication system that enables manufacturers, distributors, retailers, and consumers to verify product authenticity (through QR code scanning) for licensed entertainment merchandise. Each product has a unique ID tracked on-chain, ensuring transparency and preventing counterfeiting. 

### Key Features
- **QR Code Scanning**: Simple product verification (NFC chip support planned)
- **Blockchain Verification**: Immutable transaction history on-chain
- **Supply Chain Tracking**: Complete journey from manufacture to sale
- **Instant Authentication**: Real-time authenticity verification for consumers

---

## 🔗 On-Chain Data Structure

Data stored directly on the blockchain for each product:

```solidity
// Core Identity (32 bytes)
uint256 productId;                  // Unique identifier matching QR code

// Ownership & Status (21 bytes)
address currentOwner;                // Current holder (factory/distributor/retailer/0x0 if sold)
uint8 status;                        // 0=MANUFACTURED, 1=QC_PASSED, 2=IN_TRANSIT_DIST, etc.

// Timestamps (16 bytes)
uint32 manufactureDate;              // Unix timestamp when created
uint32 lastTransferDate;             // Unix timestamp of last ownership change
uint32 saleDate;                     // Unix timestamp when sold (0 if not sold)
uint32 recallDate;                   // Unix timestamp if recalled (0 if not recalled)

// Supply Chain Tracking (42 bytes)
address manufacturer;                 // Factory that created product
address distributor;                  // Distributor that handled product (or 0x0)
uint16 factoryId;                    // Which factory location (1, 2, 3, etc.)

// Off-chain Data Pointers (64 bytes)
bytes32 metadataHash;                // IPFS hash for product details
bytes32 certificateHash;             // IPFS hash for certificates/test results

// Verification Data (33 bytes)
bytes32 productTypeHash;             // Hash of SKU/product type for categorization
bool isAuthentic;                    // Can be marked false if found counterfeit

// Metrics (8 bytes)
uint32 scanCount;                    // Number of times QR code scanned
uint32 transferCount;                // Number of times ownership changed
```

---

## 💾 Off-Chain Data Structure

Data stored in IPFS for cost efficiency:

```
Product ID #12345:
├── Name: "Mickey Mouse Holiday Plush"
├── Serial Number: "DIS-PLUSH-2024-001"
├── Price: $29.99
├── Images: [front.jpg, back.jpg, tag.jpg]
└── Customer: Optional warranty data
```

---

## 🔄 Blockchain Transaction Flow

### 1. **Product Manufactured**
- **Action**: Factory scans new product off production line
- **Smart Contract**: `mintProduct(12345)`
- **State Update**: Status = `MANUFACTURED`, Owner = `Factory`

### 2. **Quality Control Passed**
- **Action**: QC Inspector scans and approves product
- **Smart Contract**: `markQualityPassed(12345)`
- **State Update**: Status = `QUALITY_CHECKED`, Owner = `Factory`

### 3. **Shipped to Distributor**
- **Action**: Factory ships pallet of products
- **Smart Contract**: `batchTransferToDistributor([12345...12845])`
- **State Update**: Status = `IN_TRANSIT_TO_DISTRIBUTOR`, Owner = `Distributor`

### 4. **Received at Retail Store**
- **Action**: Retailer receives and stocks product
- **Smart Contract**: `receiveInventory([12345...12394])`
- **State Update**: Status = `IN_STORE`, Owner = `Specific Retailer`

### 5. **Sold to Customer (Point of Sale)**
- **Action**: Customer purchases at checkout
- **Smart Contract**: `markAsSold(12345)`
- **State Update**: Status = `SOLD`, Owner = `#Receipt-ID`

### 6. **Customer Verification**
- **Action**: Customer scans QR code anytime
- **Smart Contract**: `verifyAuthenticity(12345)` [Read-only]
- **Returns**: Authenticity status + Complete history if authentic

---

## 🔍 User Verification Query Flow

```
1. USER SCANS QR
   ↓ (QR contains: verify.disney.com/p/12345)
   
2. BROWSER OPENS URL
   ↓ (Extracts productId = 12345)
   
3. WEB SERVER QUERIES BLOCKCHAIN
   • Connect to Polygon Network
   • Call: contract.getProductDetails(12345)
   • Receive: {status, owner, ipfsHash, dates}
   
4. VALIDATE ON-CHAIN DATA
   • Check product exists
   • Check not recalled/defective
   • Verify authorized manufacturer
   
5. FETCH OFF-CHAIN DATA (Parallel)
   • Query IPFS for metadata
   • Get product images
   
6. QUERY HISTORY (If needed)
   • Call: contract.queryFilter(events)
   • Build timeline
   
7. DISPLAY RESULT
   • If authentic: Show green checkmark + details
   • If not: Show warning + next steps
```

---

## Roles & Permissions

### **System Administrator** (Brand Headquarters)

**✅ Can:**
- Deploy and upgrade smart contracts
- Add/remove authorized manufacturer wallets
- Add/remove authorized distributor wallets
- Add/remove authorized retailer wallets
- Initiate product recalls

**❌ Cannot:**
- Change product authentication status once set
- Change ownership of products they don't currently own

### **Manufacturers** (Factory)

**✅ Can:**
- Create (mint) new products
- Set initial product metadata
- Mark products as quality-checked
- Transfer product ownership to distributors
- Update manufacturing defects if discovered

**❌ Cannot:**
- Change products from other factories
- Change Product IDs or creation dates after minting

### **Distributors** (Logistics Partners)

**✅ Can:**
- Update shipping status
- Transfer product ownership to retailers
- Report damaged products

**❌ Cannot:**
- Create new products
- Transfer products they don't own

### **Retailers** (Authorized Stores)

**✅ Can:**
- Mark products as sold
- Record sale date/time
- Process returns (mark as returned)

**❌ Cannot:**
- Create new products
- Accept products not sent by authorized distributors
- Change ownership of sold products

### **Consumers** (End Customers)

**✅ Can (No Wallet Required):**
- Verify product authenticity (read-only)
- View complete product history (read-only)

**❌ Cannot:**
- Change any blockchain data

---

## Technical Stack

- **Blockchain**: Polygon Network
- **Storage**: IPFS for off-chain data
- **Smart Contracts**: Solidity
- **Frontend**: Web-based verification portal
- **Authentication**: QR Codes (NFC planned)

---

## Setup and Deployment

- We intend to use Remix IDE to deploy our contracts on the Ethereum network
- Setup would require creating the respective wallets with their addresses before deploying contract on the platform
(TBC)
- To use the CLI, you'll need to install Node.js, ethers.js, and dotenv. Ensure that you have the private keys necessary, in a .env file at the root level
- You can run the CLI with the command
```node cli.js call {role} {functionName} [arguments]```

Examples:
```node cli.js call contract productCore 1001```
```node cli.js call manu mintProduct 1001 1 "QmHash..." 1734825600```

- For the verification frontend, you would need to run the following commands:
```
cd frontend
npm i
node server.js
```
---

Once it is running, you can visit the page on your localhost and you'll have the frontend available, where you can generate and verify the product using the QR code

## 📝 License

Going with MIT license here
