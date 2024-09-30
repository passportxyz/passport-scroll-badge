import { ethers } from "ethers";
import * as originalDocument from "./originalDocument.json";

// Define the domain (from the JSON)
const domain = {
  name: "VerifiableCredential",
};

// The signature from the JSON
const signature = originalDocument.credential.proof.proofValue;

const types = originalDocument.credential.proof.eip712Domain.types;
const message = {
  ...originalDocument.credential,
};

// @ts-ignore
delete message.proof.eip712Domain;

// Console log functions
function logHash(name: string, hash: string) {
  console.log(`${name}: ${ethers.BigNumber.from(hash).toString()}`);
  console.log(`${name} (hex): ${hash}`);
}

function logAddress(name: string, address: string) {
  console.log(`${name}: ${address.toLowerCase()}`);
}

// Output
console.log("Verifying credential for document:");
console.log(`Document issuer: ${message.issuer}`);
console.log(`Document issuanceDate: ${message.issuanceDate}`);
console.log(`Document expirationDate: ${message.expirationDate}`);

console.log(`type: ${message.proof.type}`);
console.log(`verificationMethod: ${message.proof.verificationMethod}`);

// Calculate the domain separator
const domainSeparator = ethers.utils._TypedDataEncoder.hashDomain(domain);
logHash("Domain Separator", domainSeparator);

// Calculate the EIP-712 hash
const eip712Hash = ethers.utils._TypedDataEncoder.hash(domain, types, message);
logHash("EIP-712 Hash", eip712Hash);

// Split the signature
const splitSignature = ethers.utils.splitSignature(signature);

// Recover the signer's address using EIP-712 hash
const recoveredAddress = ethers.utils.recoverAddress(
  eip712Hash,
  splitSignature
);
logAddress("Recovered address", recoveredAddress);

const expectedIssuer = "0xd6f8D6CA86AA01E551a311D670a0d1bD8577E5FB";
logAddress("Expected issuer", expectedIssuer);

if (recoveredAddress.toLowerCase() === expectedIssuer.toLowerCase()) {
  console.log("Credential verification successful");
} else {
  console.log("INVALID_SIGNER");
}

console.log("Split Signature:", {
  r: splitSignature.r,
  s: splitSignature.s,
  v: splitSignature.v,
});

// Log the types structure
console.log("Types structure:");
console.log(JSON.stringify(types, null, 2));

// Log the message structure
console.log("Message structure:");
console.log(JSON.stringify(message, null, 2));
