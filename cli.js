#!/usr/bin/env node
import dotenv from "dotenv";
import { ethers } from "ethers";

dotenv.config();

const CONTRACTS = {
    adm: "0xced719c26c4406b4f2966a9868cc28e325c433f6",
    dst: "0x5bdbc77ba6fd354a22c3e8dfb122722d321f3b91",
    qc: "0x08c0739effb8fd1072c4c3b715fc8a09449fd225",
    rl: "0xeade29a6daf40cc19671aec021d692cddf407fec",
    cust: "0xb30ee27129b52aa17492b4bc728080d8c328eb25",
    manu: "0x43e5bd17bdd2a599050dcbf9dfbd65b04caeeb12",
    contract: "0x77196Eac8E14C73d403dE8f1872aC4f9aBEC79c8",
};

const PRIVATE_KEYS = {
    adm: process.env.PRIVATE_KEY_ADM,
    dst: process.env.PRIVATE_KEY_DST,
    qc: process.env.PRIVATE_KEY_QC,
    rl: process.env.PRIVATE_KEY_RL,
    cust: process.env.PRIVATE_KEY_CUST,
    manu: process.env.PRIVATE_KEY_MANU,
};

const CONTRACT_ABI = [

    // manufacturer functions
    "function mintProduct(uint256 productId, uint16 factoryId, string ipfsHash, uint32 manufactureDate)",
    "function transferToDistributor(uint256 productId, address distributor, uint32 transferDate)",
    
    // QC functions
    "function markQualityPassed(uint256 productId, uint32 checkDate)",

    // distributor functions
    "function acceptDistributorDelivery(uint256 productId)",
    "function transferToRetailer(uint256 productId, address retailer, uint32 transferDate)",

    // retailer functions
    "function acceptRetailerDelivery(uint256 productId)",
    "function sellProduct(uint256 productId, address customer, uint32 saleDate)",

    // product functions
    "function getProductCore(uint256) view returns (uint256 productId, uint8 status, address manufacturer, address currentOwner, bool isAuthentic, uint16 factoryId)",
    "function getProductExtended(uint256) view returns (string ipfsHash, uint32 manufactureTimestamp, uint32 qualityCheckDate, uint32 saleDate, uint32 scanCount, uint32 transferCount)",
    "function getProductChain(uint256) view returns (address distributor, address retailer, bytes32 receiptIdHash)",
    "function getManufacturerProducts(address) view returns (uint256[] memory)",
    "function getDistributorProducts(address) view returns (uint256[] memory)",
    "function getRetailerProducts(address) view returns (uint256[] memory)",
];

function getProvider() {
    return new ethers.JsonRpcProvider(
        "https://rpc-amoy.polygon.technology/",
        80002
    );
}

function parseArg(arg) {
    if (typeof arg !== "string") return arg;

    // Strip p-prefix: "p1001" → "1001"
    if (/^p\d+$/i.test(arg)) {
        return arg.slice(1);
    }

    // Convert numeric strings ONLY if all digits
    if (/^\d+$/.test(arg)) {
        return Number(arg);
    }

    // Otherwise leave as-is (addresses, strings)
    return arg;
}

function formatResult(result, abiFragment) {
    // Extract return variable names from ABI
    const returnsMatch = abiFragment.match(/returns\s*\((.*?)\)/);
    if (!returnsMatch) {
        // No named returns, just show raw result
        if (Array.isArray(result)) {
            return result.map((item, idx) => `[${idx}]: ${formatValue(item)}`).join('\n');
        }
        return formatValue(result);
    }

    const returnParams = returnsMatch[1].split(',').map(p => {
        const parts = p.trim().split(' ');
        // Handle cases like "uint256 productId" or "uint256[] memory"
        const name = parts[parts.length - 1]; // Last part is the variable name
        return name || `value${parts.length}`;
    });

    // If result is a struct/tuple with named properties
    const formatted = {};
    
    if (Array.isArray(result)) {
        returnParams.forEach((name, idx) => {
            formatted[name] = formatValue(result[idx], name);
        });
    } else if (typeof result === 'object' && result !== null) {
        // Result might already have named properties
        Object.keys(result).forEach(key => {
            if (isNaN(key)) { // Skip numeric indices
                formatted[key] = formatValue(result[key], key);
            }
        });
        
        // If no named properties, use indices
        if (Object.keys(formatted).length === 0) {
            returnParams.forEach((name, idx) => {
                formatted[name] = formatValue(result[idx], name);
            });
        }
    } else {
        formatted[returnParams[0]] = formatValue(result, returnParams[0]);
    }

    // Pretty print the object
    return JSON.stringify(formatted, null, 2);
}

function getStatusString(statusCode) {
    const statusMap = {
        0: "MANUFACTURED",
        1: "QUALITY_CHECKED",
        2: "IN_TRANSIT_TO_DISTRIBUTOR",
        3: "WITH_DISTRIBUTOR",
        4: "IN_TRANSIT_TO_RETAILER",
        5: "WITH_RETAILER",
        6: "SOLD",
        7: "RETURNED"
    };
    return statusMap[statusCode] || `UNKNOWN(${statusCode})`;
}

function formatValue(value, fieldName) {
    // Handle status enum specifically
    if (fieldName === 'status' && (typeof value === 'number' || typeof value === 'bigint')) {
        const statusCode = Number(value);
        return `${statusCode} (${getStatusString(statusCode)})`;
    }
    
    // Handle BigInt
    if (typeof value === 'bigint') {
        return value.toString();
    }
    
    // Handle ethers BigNumber
    if (value && typeof value === 'object' && value._isBigNumber) {
        return value.toString();
    }
    
    // Handle arrays
    if (Array.isArray(value)) {
        return value.map(v => formatValue(v));
    }
    
    // Handle boolean
    if (typeof value === 'boolean') {
        return value;
    }
    
    // Handle addresses (keep as is)
    if (typeof value === 'string' && value.startsWith('0x')) {
        return value;
    }
    
    // Everything else
    return value;
}

async function callFunction(contractAddress, funcName, params, roleAlias) {
    const provider = getProvider();

    const code = await provider.getCode(contractAddress);
    if (code === "0x") {
        console.error("❌ No contract deployed at:", contractAddress);
        return;
    }

    // Check if this is a view function (read-only)
    const abiFragment = CONTRACT_ABI.find(f => f.includes(`function ${funcName}`));
    const isViewFunction = abiFragment && abiFragment.includes("view");

    let contract;
    if (isViewFunction) {
        // Read-only: use provider
        contract = new ethers.Contract(contractAddress, CONTRACT_ABI, provider);
        console.log("📖 Calling view function (read-only)...");
    } else {
        // Write function: need wallet for the ROLE (not contract address)
        const privateKey = PRIVATE_KEYS[roleAlias];
        if (!privateKey) {
            console.error(`❌ No private key found for role: ${roleAlias}`);
            console.error(`   Add PRIVATE_KEY_${roleAlias.toUpperCase()} to your .env file`);
            return;
        }
        const wallet = new ethers.Wallet(privateKey, provider);
        contract = new ethers.Contract(contractAddress, CONTRACT_ABI, wallet);
        console.log(`✍️  Calling as role: ${roleAlias}`);
        console.log(`   From address: ${wallet.address}`);
        console.log(`   To contract: ${contractAddress}`);
    }

    if (!contract[funcName]) {
        console.error(`❌ This function does NOT exist in ABI: ${funcName}`);
        return;
    }

    try {
        const result = await contract[funcName](...params);

        if (isViewFunction) {
            console.log("✔ Function executed successfully.");
            console.log("Result:");
            
            // Format result as key-value pairs
            const formatted = formatResult(result, abiFragment);
            console.log(formatted);
        } else {
            console.log("✔ Transaction sent!");
            console.log("Transaction hash:", result.hash);
            console.log("⏳ Waiting for confirmation...");
            const receipt = await result.wait();
            console.log("✅ Transaction confirmed in block:", receipt.blockNumber);
            console.log(`   Gas used: ${receipt.gasUsed.toString()}`);
        }
    } catch (err) {
        console.error("❌ Error calling function:");
        console.error(err.message || err);
    }
}

async function main() {
    const [command, roleAlias, funcName, ...params] = process.argv.slice(2);

    if (!command) {
        console.log(`
Usage:
  node cli.js call {role} {functionName} [params...]

Examples:
  # Read from contract (no role needed, use 'contract' or any alias)
  node cli.js call contract productCore 1001

  # Write as manufacturer
  node cli.js call manu mintProduct 1001 1 "QmHash..." 1734825600

  # Write as QC
  node cli.js call qc markQualityPassed 1001 1734825600

  # Write as distributor
  node cli.js call dst acceptDistributorDelivery 1001

Available role aliases:
  ${Object.keys(CONTRACTS).join(", ")}

Note: All write operations target the main contract at:
  ${CONTRACTS.contract}
`);
        return;
    }

    // Always use the main contract address for function calls
    const contractAddress = CONTRACTS.contract;

    // Validate role alias exists (for better error messages)
    if (!CONTRACTS[roleAlias]) {
        console.error(`❌ Unknown role alias: ${roleAlias}`);
        console.log("Available:", Object.keys(CONTRACTS).join(", "));
        return;
    }

    const parsedParams = params.map(parseArg);

    if (command === "call") {
        await callFunction(contractAddress, funcName, parsedParams, roleAlias);
        return;
    }

    console.error("❌ Unknown command:", command);
}

main();