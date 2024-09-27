// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
// import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
// import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

import {IEAS, Attestation} from "@eas/contracts/IEAS.sol";

struct CredentialSubject {
    string _hash;
    string id;
    string provider;
}

struct Proof {
    string _context;
    string created;
    string proofPurpose;
    string _type;
    string verificationMethod;
}

struct Document {
    string _context;
    CredentialSubject credentialSubject;
    string expirationDate;
    string issuanceDate;
    string issuer;
    Proof proof;
    string[] _type;
}



/// @title DevStampBadgeVerifier
/// @notice Verifies EIP712-signed credentials and issues badge attestation(s)

//  is
//   Initializable,
//   UUPSUpgradeable,
//   OwnableUpgradeable,
//   PausableUpgradeable

contract DevStampBadgeVerifier
{
    // The global EAS contract.
    // IEAS private immutable _eas;
    mapping(address => uint) public nonces;
    string public name;

    function _getInitializedVersion() public pure returns (string memory) {
        return "1.0.0";
    }

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
    constructor() {
        name = "DevStampBadgeVerifier";
    }

    function computeDomainSeparator() public view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {

        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        computeDomainSeparator(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");
        }
    }

    

}

// Below is an example of EIP712 signature verification
// from https://github.com/tim-schultz/passport-vc-verification/tree/main

// pragma solidity >=0.8.4;
// 
// import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
// import { VcVerifier } from "./VCVerifier.sol";
// import { DIDpkhAdapter } from "./DIDpkhAdapter.sol";
// import { AttestationStation } from "./AttestationStation.sol";
// 
// 
// contract DIDStampVcVerifier is VcVerifier, DIDpkhAdapter {
//     bytes32 private constant PROOF_TYPE_HASH =
//         keccak256("Proof(string @context,string created,string proofPurpose,string type,string verificationMethod)");
// 
//     bytes32 private constant CREDENTIAL_SUBJECT_TYPEHASH =
//         keccak256("CredentialSubject(string hash,string id,string provider)");
// 
//     bytes32 private constant DOCUMENT_TYPEHASH =
//         keccak256(
//             "Document(string @context,CredentialSubject credentialSubject,string expirationDate,string issuanceDate,string issuer,Proof proof,string[] type)CredentialSubject(string hash,string id,string provider)Proof(string @context,string created,string proofPurpose,string type,string verificationMethod)"
//         );
// 
//     address public _verifier;
//     address public _attestationStation;
// 
//     AttestationStation.AttestationData[] public _attestations;
// 
//     event Verified(string indexed id, string iamHash, string provider);
// 
//     mapping(string => string) public verifiedStamps;
// 
//     constructor(string memory domainName, address verifier, address attestationStation) VcVerifier(domainName) {
//         _verifier = verifier;
//         _attestationStation = attestationStation;
//     }
// 
//     function hashCredentialSubject(CredentialSubject calldata subject) public pure returns (bytes32) {
//         return
//             keccak256(
//                 abi.encode(
//                     CREDENTIAL_SUBJECT_TYPEHASH,
//                     keccak256(bytes(subject._hash)),
//                     keccak256(bytes(subject.id)),
//                     keccak256(bytes(subject.provider))
//                 )
//             );
//     }
// 
//     function hashCredentialProof(Proof calldata proof) public pure returns (bytes32) {
//         return
//             keccak256(
//                 abi.encode(
//                     PROOF_TYPE_HASH,
//                     keccak256(bytes(proof._context)),
//                     keccak256(bytes(proof.created)),
//                     keccak256(bytes(proof.proofPurpose)),
//                     keccak256(bytes(proof._type)),
//                     keccak256(bytes(proof.verificationMethod))
//                 )
//             );
//     }
// 
//     function hashDocument(Document calldata document) public pure returns (bytes32) {
//         bytes32 credentialSubjectHash = hashCredentialSubject(document.credentialSubject);
//         bytes32 proofHash = hashCredentialProof(document.proof);
// 
//         return
//             keccak256(
//                 abi.encode(
//                     DOCUMENT_TYPEHASH,
//                     keccak256(bytes(document._context)),
//                     credentialSubjectHash,
//                     keccak256(bytes(document.expirationDate)),
//                     keccak256(bytes(document.issuanceDate)),
//                     keccak256(bytes(document.issuer)),
//                     proofHash,
//                     _hashArray(document._type)
//                 )
//             );
//     }
// 
//     function verifyStampVc(Document calldata document, uint8 v, bytes32 r, bytes32 s) public returns (bool) {
//         bytes32 vcHash = hashDocument(document);
//         bytes32 digest = ECDSA.toTypedDataHash(DOMAIN_SEPARATOR, vcHash);
// 
//         address issuerAddress = DIDpkhAdapter.pseudoResolveDidIssuer(document.issuer);
// 
//         address recoveredAddress = ECDSA.recover(digest, v, r, s);
// 
//         // Here we could check the issuer's address against an on-chain registry.
//         // We could provide a verifying contract address when signing the credential which could correspond to this contract
//         require(recoveredAddress == issuerAddress, "VC verification failed issuer does not match signature");
// 
//         verifiedStamps[document.credentialSubject.id] = document.credentialSubject._hash;
// 
//         emit Verified(
//             document.credentialSubject.id,
//             document.credentialSubject._hash,
//             document.credentialSubject.provider
//         );
// 
//         AttestationStation attestationStation = AttestationStation(_attestationStation);
//         AttestationStation.AttestationData memory attestation = AttestationStation.AttestationData(
//             msg.sender,
//             "Verified",
//             "yes"
//         );
//         _attestations.push(attestation);
// 
//         attestationStation.attest(_attestations);
//         return true;
//     }
// }
