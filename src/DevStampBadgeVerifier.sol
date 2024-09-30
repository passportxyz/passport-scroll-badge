// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {console2} from "forge-std/console2.sol";

contract DevStampBadgeVerifier is EIP712 {
    string public constant SIGNING_DOMAIN = "VerifiableCredential";
    string public constant SIGNATURE_VERSION = "1";

    struct Context {
        string hash;
        string provider;
    }

    struct CredentialSubject {
        Context context;
        string hash;
        string id;
        string provider;
    }

    struct Proof {
        string context;
        string created;
        string proofPurpose;
        string proofType;
        string verificationMethod;
    }

    struct Document {
        string[] context;
        CredentialSubject credentialSubject;
        string expirationDate;
        string issuanceDate;
        string issuer;
        Proof proof;
        string[] documentType;
    }

    constructor() EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {}

    function hashStringArray(string[] memory array) internal pure returns (bytes32) {
        bytes32[] memory hashedArray = new bytes32[](array.length);
        for (uint i = 0; i < array.length; i++) {
            hashedArray[i] = keccak256(bytes(array[i]));
        }
        return keccak256(abi.encodePacked(hashedArray));
    }

    function hashDocument(Document memory document) public view returns (bytes32) {
        console2.log("Hashing document: ", document.credentialSubject.hash);
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("Document(string[] @context,CredentialSubject credentialSubject,string expirationDate,string issuanceDate,string issuer,Proof proof,string[] type)CredentialSubject(@context @context,string hash,string id,string provider)@context(string hash,string provider)Proof(string @context,string created,string proofPurpose,string type,string verificationMethod)"),
            hashStringArray(document.context),
            keccak256(abi.encode(
                keccak256("CredentialSubject(@context @context,string hash,string id,string provider)@context(string hash,string provider)"),
                keccak256(abi.encode(
                    keccak256("@context(string hash,string provider)"),
                    keccak256(bytes(document.credentialSubject.context.hash)),
                    keccak256(bytes(document.credentialSubject.context.provider))
                )),
                keccak256(bytes(document.credentialSubject.hash)),
                keccak256(bytes(document.credentialSubject.id)),
                keccak256(bytes(document.credentialSubject.provider))
            )),
            keccak256(bytes(document.expirationDate)),
            keccak256(bytes(document.issuanceDate)),
            keccak256(bytes(document.issuer)),
            keccak256(abi.encode(
                keccak256("Proof(string @context,string created,string proofPurpose,string type,string verificationMethod)"),
                keccak256(bytes(document.proof.context)),
                keccak256(bytes(document.proof.created)),
                keccak256(bytes(document.proof.proofPurpose)),
                keccak256(bytes(document.proof.proofType)),
                keccak256(bytes(document.proof.verificationMethod))
            )),
            hashStringArray(document.documentType)
        )));
    }

    function verifyCredential(Document calldata document, uint8 v, bytes32 r, bytes32 s) public view {
        console2.log("Verifying credential for document:");
        console2.log("Document issuer:", document.issuer);
        console2.log("Document issuanceDate:", document.issuanceDate);
        console2.log("Document expirationDate:", document.expirationDate);

        bytes32 digest = hashDocument(document);
        console2.log("Computed digest:", uint256(digest));

        address recoveredAddress = ECDSA.recover(digest, v, r, s);
        console2.log("Recovered address:", recoveredAddress);

        address issuer = 0xd6f8D6CA86AA01E551a311D670a0d1bD8577E5FB;
        console2.log("Expected issuer:", issuer);

        require(recoveredAddress != address(0) && recoveredAddress == issuer, "INVALID_SIGNER");
        console2.log("Credential verification successful");
    }
}