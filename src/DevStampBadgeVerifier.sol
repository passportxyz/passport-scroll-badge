// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
// import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
// import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {IEAS, Attestation} from "@eas/contracts/IEAS.sol";
import {console2} from "forge-std/console2.sol";

struct CredentialSubjectContext {
    string _hash;
    string provider;
}

struct CredentialSubject {
    string _hash;
    string id;
    string provider;
    CredentialSubjectContext _context;
}

struct Proof {
    string _context;
    string created;
    string proofPurpose;
    string _type;
    string verificationMethod;
}

struct Document {
    string[] _context;
    CredentialSubject credentialSubject;
    string expirationDate;
    string issuanceDate;
    string issuer;
    Proof proof;
    string[] _type;
}

struct EIP712Domain {
    string name;
}

/// @title DevStampBadgeVerifier
/// @notice Verifies EIP712-signed credentials and issues badge attestation(s)

//  is
//   Initializable,
//   UUPSUpgradeable,
//   OwnableUpgradeable,
//   PausableUpgradeable

contract DevStampBadgeVerifier {
    // The global EAS contract.
    // IEAS private immutable _eas;
    mapping(address => uint256) public nonces;
    string public name;

    //     /**
    //    * @dev Creates a new resolver.
    //    * @notice Initializer function responsible for setting up the contract's initial state.
    //    * @param eas The address of the global EAS contract
    //    */
    //     function initialize(IEAS eas) public initializer {
    //         __Ownable_init();
    //         __Pausable_init();
    //         // __UUPSUpgradeable_init();

    //         require(address(eas) != address(0), "Invalid EAS address");
    //         _eas = eas;
    // name = "DevStampBadgeVerifier";
    //     }

    bytes32 private constant _PROOF_TYPE_HASH =
        keccak256("Proof(string @context,string created,string proofPurpose,string type,string verificationMethod)");

    bytes32 private constant _CREDENTIAL_SUBJECT_CONTEXT_TYPEHASH =
        keccak256("@context(string hash,string provider)");

    bytes32 private constant _DOCUMENT_TYPEHASH = keccak256(
        "Document(string[] @context,CredentialSubject credentialSubject,string expirationDate,string issuanceDate,string issuer,Proof proof,string[] type)CredentialSubject(@context @context,string hash,string id,string provider)@context(string hash,string provider)Proof(string @context,string created,string proofPurpose,string type,string verificationMethod)"
    );

    bytes32 private constant _CREDENTIAL_SUBJECT_TYPEHASH = keccak256(
        "CredentialSubject(@context @context,string hash,string id,string provider)@context(string hash,string provider)"
    );

    bytes32 private constant _EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name)");

    

    function _hashArray(string[] memory array) internal pure returns (bytes32 result) {
        bytes32[] memory hashedArray = new bytes32[](array.length);
        for (uint i = 0; i < array.length; i++) {
            hashedArray[i] = keccak256(bytes(array[i]));
        }
        return keccak256(abi.encodePacked(hashedArray));
    }

    function hashCredentialSubjectContext(CredentialSubjectContext memory context) public pure returns (bytes32) {
        bytes32 result = keccak256(
            abi.encode(
                _CREDENTIAL_SUBJECT_CONTEXT_TYPEHASH,
                keccak256(bytes(context._hash)),
                keccak256(bytes(context.provider))
            )
        );
        console2.log("hashCredentialSubjectContext result:", uint256(result));
        return result;
    }

    function hashCredentialSubject(CredentialSubject memory subject) public pure returns (bytes32) {
        bytes32 result = keccak256(
            abi.encode(
                _CREDENTIAL_SUBJECT_TYPEHASH,
                hashCredentialSubjectContext(subject._context),
                keccak256(bytes(subject._hash)),
                keccak256(bytes(subject.id)),
                keccak256(bytes(subject.provider))
            )
        );
        console2.log("hashCredentialSubject result:", uint256(result));
        return result;
    }

    function hashCredentialProof(Proof memory proof) public pure returns (bytes32) {
        
        bytes32 result = keccak256(
            abi.encode(
                _PROOF_TYPE_HASH,
                keccak256(bytes(proof._context)),
                keccak256(bytes(proof.created)),
                keccak256(bytes(proof.proofPurpose)),
                keccak256(bytes(proof._type)),
                keccak256(bytes(proof.verificationMethod))
            )
        );
        console2.log("hashCredentialProof result:", uint256(result));
        return result;
    }

    function hashDocument(Document memory document) public pure returns (bytes32) {
        return keccak256(abi.encode(
            _DOCUMENT_TYPEHASH,
            _hashArray(document._context),
            hashCredentialSubject(document.credentialSubject),
            keccak256(bytes(document.expirationDate)),
            keccak256(bytes(document.issuanceDate)),
            keccak256(bytes(document.issuer)),
            hashCredentialProof(document.proof),
            _hashArray(document._type)
        ));
    }

    function computeDomainSeparator() public view virtual returns (bytes32) {
        EIP712Domain memory eip712Domain = EIP712Domain({
            name: "VerifiableCredential"
        });

        bytes32 domainSeparator = keccak256(
            abi.encode(
                _EIP712DOMAIN_TYPEHASH,
                keccak256(bytes(eip712Domain.name))
            )
        );

        return domainSeparator;
    }

    function verifyCredential(Document calldata document, uint8 v, bytes32 r, bytes32 s) public view {
        console2.log("Verifying credential for document:");
        console2.log("Document issuer:", document.issuer);
        console2.log("Document issuanceDate:", document.issuanceDate);
        console2.log("Document expirationDate:", document.expirationDate);

        bytes32 domainSeparator = computeDomainSeparator();
        console2.log("Domain Separator:", uint256(domainSeparator));

        bytes32 documentHash = hashDocument(document);
        console2.log("Document Hash:", uint256(documentHash));

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, documentHash));
        console2.log("Computed digest:", uint256(digest));

        bytes32 digestECDSA = ECDSA.toTypedDataHash(domainSeparator, documentHash);
        console2.log("Computed digestECDSA:", uint256(digestECDSA));

        address recoveredAddress = ECDSA.recover(digest, v, r, s);
        console2.log("Recovered address:", recoveredAddress);

        address issuer = 0xd6f8D6CA86AA01E551a311D670a0d1bD8577E5FB;
        console2.log("Expected issuer:", issuer);

        require(recoveredAddress != address(0) && recoveredAddress == issuer, "INVALID_SIGNER");
        console2.log("Credential verification successful");
    }
}
