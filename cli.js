#!/usr/bin/env node
import { ethers } from "ethers";
import dotenv from "dotenv";

dotenv.config();

function getProvider() {

    return new ethers.JsonRpcProvider(
        "https://rpc-amoy.polygon.technology/",
        80002
    );

}


// made this mapping to keep track of addresses of wallets
const contractsMapping = {
    adm: "0xced719c26c4406b4f2966a9868cc28e325c433f6",
    dst: "0x5bdbc77ba6fd354a22c3e8dfb122722d321f3b91",
    qc: "0x08c0739effb8fd1072c4c3b715fc8a09449fd225",
    rl: "0xeade29a6daf40cc19671aec021d692cddf407fec",
    cust: "0xb30ee27129b52aa17492b4bc728080d8c328eb25",
    manu: "0x43e5bd17bdd2a599050dcbf9dfbd65b04caeeb12",
    contract: "0x77196Eac8E14C73d403dE8f1872aC4f9aBEC79c8",
};


// added to use private keys from .env file for write operations
const privateKeys = {
    adm: process.env.PRIVATE_KEY_ADM,
    dst: process.env.PRIVATE_KEY_DST,
    qc: process.env.PRIVATE_KEY_QC,
    rl: process.env.PRIVATE_KEY_RL,
    cust: process.env.PRIVATE_KEY_CUST,
    manu: process.env.PRIVATE_KEY_MANU,
};


// this is a mapping of all the allowed APIs via our CLI
const contractABI = [
    "function mintProduct(uint256 productId, uint16 factoryId, string ipfsHash, uint32 manufactureDate)",
    "function transferToDistributor(uint256 productId, address distributor, uint32 transferDate)",
    "function markQualityPassed(uint256 productId, uint32 checkDate)",
    "function acceptDistributorDelivery(uint256 productId)",
    "function transferToRetailer(uint256 productId, address retailer, uint32 transferDate)",
    "function acceptRetailerDelivery(uint256 productId)",
    "function sellProduct(uint256 productId, address customer, uint32 saleDate)",
    "function getProductCore(uint256) view returns (uint256 productId, uint8 status, address manufacturer, address currentOwner, bool isAuthentic, uint16 factoryId)",
    "function getProductExtended(uint256) view returns (string ipfsHash, uint32 manufactureTimestamp, uint32 qualityCheckDate, uint32 saleDate, uint32 scanCount, uint32 transferCount)",
    "function getProductChain(uint256) view returns (address distributor, address retailer, bytes32 receiptIdHash)",
    "function getManufacturerProducts(address) view returns (uint256[] memory)",
    "function getDistributorProducts(address) view returns (uint256[] memory)",
    "function getRetailerProducts(address) view returns (uint256[] memory)",
];


// brought object status structure here
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

function formatVal(value, fieldName) {
    
    // added formatting for the status field
    if (fieldName === 'status' && (typeof value === 'number')) {
        const statusCode = Number(value);
        return `${statusCode} (${getStatusString(statusCode)})`;
    }
    
    // considering timestamps
    if (typeof value === 'bigint') {
        return value.toString();
    }
    
    // considering ethers
    if (value && typeof value === 'object' && value._isBigNumber) {
        return value.toString();
    }
    
    // considering factory numbers 
    if (Array.isArray(value)) {
        return value.map(v => formatVal(v));
    }
    
    // considering authenticity field
    if (typeof value === 'boolean') {
        return value;
    }
    
    // considering address 
    if (typeof value === 'string' && value.startsWith('0x')) {
        return value;
    }
    
    return value;
}


// added this so that for readable results
function formatResult(result, calledFunction) {

    // created this section so that we can display labels in output
    const returnVar = calledFunction.match(/returns\s*\((.*?)\)/);

    // just raw values
    if (!returnVar) {

        if (Array.isArray(result)) {
            return result.map((item, idx) => `[${idx}]: ${formatVal(item)}`).join('\n');
        }

        return formatVal(result);
    }

    const returnParams = returnVar[1].split(',').map(r => {

        const returnVarList = r.trim().split(' ');

        // cases like uint256 productId
        const name = returnVarList[returnVarList.length - 1];
        return name || `value${returnVarList.length}`;

    });

    // If result is a struct/tuple with named properties
    const formatted = {};
    
    if (Array.isArray(result)) {

        // create key-value pairs
        returnParams.forEach((name, idx) => {
            formatted[name] = formatVal(result[idx], name);
        });

    } else if (typeof result === 'object' && result !== null) {

        // if result has named fields
        Object.keys(result).forEach(key => {
            if (isNaN(key)) { // Skip numeric indices
                formatted[key] = formatVal(result[key], key);
            }
        });
        
        if (Object.keys(formatted).length === 0) {
            returnParams.forEach((name, idx) => {
                formatted[name] = formatVal(result[idx], name);
            });
        }

    } else {
        formatted[returnParams[0]] = formatVal(result, returnParams[0]);
    }

    return JSON.stringify(formatted, null, 2);
}



async function triggerAction(contractAddress, funcName, params, roleAlias) {

    const provider = getProvider();
    let contract;

    const addressCode = await provider.getCode(contractAddress);

    if (addressCode === "0x") {

        console.error(`No contract deployed at: ${contractAddress}`);
        return;

    }

    const calledFunction = contractABI.find(f => f.includes(`function ${funcName}`));
    const isViewFunction = calledFunction && calledFunction.includes("view");

    if (isViewFunction) {

        // for read only functions, used the standard provider since anyone can hit it
        contract = new ethers.Contract(contractAddress, contractABI, provider);

    } else {

        // added signing with role based access for write functions
        const privateKey = privateKeys[roleAlias];

        if (!privateKey) {

            console.error(`Unauthorized access! No private key found!`);
            return;

        }

        const wallet = new ethers.Wallet(privateKey, provider);

        contract = new ethers.Contract(contractAddress, contractABI, wallet);
        console.log(`Action triggered by ${roleAlias} from ${wallet.address}`);
    }

    if (!contract[funcName]) {

        console.error(`${funcName} functionality does not exist!`);
        return;

    }

    // added result processing in try cathc for error handling 
    try {

        const result = await contract[funcName](...params);

        if (isViewFunction) {

            console.log(`${funcName} was successful!`);
            console.log("Result: ");

            const formatted = formatResult(result, calledFunction);
            console.log(formatted);

        } else {

            // added more result text for better CLI
            console.log("Transaction sent!");
            console.log(`Hash: ${result.hash}`);

            // added to account for delay
            console.log("Processing transaction...");

            const transactionResult = await result.wait();
            console.log(`Transaction confirmed in block: ${transactionResult.blockNumber}`);

            // added for validation
            console.log(`Gas used: ${transactionResult.gasUsed.toString()}`);

        }

    } catch (err) {
        console.error(`Error calling function: ${err.message || err}`);
    }

}


function parseArg(arg) {

    if (typeof arg !== "string") {
        return arg;
    }

    // regex for products that are of type pXXX
    if (/^p\d+$/i.test(arg)) {
        return arg.slice(1);
    }

    // number string regex
    if (/^\d+$/.test(arg)) {
        return Number(arg);
    }

    return arg;
}


async function main() {

    const [command, roleAlias, funcName, ...params] = process.argv.slice(2);

    // i added error handling for bad commands
    if (!command) {

        console.log(`
            Unrecognized command! Cannot process!

            Command syntax:
            node cli.js call {role} {functionName} [arguments]

            Example:
            node cli.js call contract productCore 1001
            node cli.js call manu mintProduct 1001 1 "QmHash..." 1734825600
        `);
        return;

    }

    // smart contract is deployed at this address
    const contractAddress = contractsMapping.contract;

    const parsedArgs = params.map(parseArg);

    if (command === "call") {
        await triggerAction(contractAddress, funcName, parsedArgs, roleAlias);
        return;
    }
}

main();