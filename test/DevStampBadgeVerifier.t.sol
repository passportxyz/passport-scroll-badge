// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/test.sol";
import {SigUtils} from "./utils/SigUtils.sol";
import "src/DevStampBadgeVerifier.sol";
import {console2} from "forge-std/console2.sol";

contract DevStampBadgeVerifierTest is Test {
    DevStampBadgeVerifier internal verifier;
    SigUtils internal sigUtils;

    uint256 internal ownerPrivateKey;
    uint256 internal spenderPrivateKey;

    address internal owner;
    address internal spender;

    function setUp() public {
        verifier = new DevStampBadgeVerifier();
        // sigUtils = new SigUtils(verifier.computeDomainSeparator());

        ownerPrivateKey = 0xA11CE;
        spenderPrivateKey = 0xB0B;

        owner = vm.addr(ownerPrivateKey);
        spender = vm.addr(spenderPrivateKey);
    }

    function createDocument() public pure returns (DevStampBadgeVerifier.Document memory) {
        // Initialize context array
        string[] memory contextArray = new string[](2);
        contextArray[0] = "https://www.w3.org/2018/credentials/v1";
        contextArray[1] = "https://w3id.org/vc/status-list/2021/v1";

        // Initialize CredentialSubjectContext
        DevStampBadgeVerifier.Context memory subjectContext = DevStampBadgeVerifier.Context({
            hash: "https://schema.org/Text",
            provider: "https://schema.org/Text"
        });

        // Initialize CredentialSubject
        DevStampBadgeVerifier.CredentialSubject memory subject = DevStampBadgeVerifier.CredentialSubject({
            context: subjectContext,
            hash: "v0.0.0:ymd16bDo5s725oPIBtT4mHgF5W6PJNjasqDJ8r801Jk=",
            id: "did:pkh:eip155:1:0x0636F974D29d947d4946b2091d769ec6D2d415DE",
            provider: "Linkedin"
        });

        // Initialize Proof
        DevStampBadgeVerifier.Proof memory proofData = DevStampBadgeVerifier.Proof({
            context: "https://w3id.org/security/suites/eip712sig-2021/v1",
            created: "2024-09-09T19:20:01.906Z",
            proofPurpose: "assertionMethod",
            proofType: "EthereumEip712Signature2021",
            verificationMethod: "did:ethr:0xd6f8d6ca86aa01e551a311d670a0d1bd8577e5fb#controller"
        });

        // Initialize type array
        string[] memory typeArray = new string[](1);
        typeArray[0] = "VerifiableCredential";

        // Initialize Document
        DevStampBadgeVerifier.Document memory doc = DevStampBadgeVerifier.Document({
            context: contextArray,
            credentialSubject: subject,
            expirationDate: "2024-12-08T19:20:01.906Z",
            issuanceDate: "2024-09-09T19:20:01.906Z",
            issuer: "did:ethr:0xd6f8d6ca86aa01e551a311d670a0d1bd8577e5fb",
            proof: proofData,
            documentType: typeArray
        });

        return doc;
    }

    function testCredentialVerification() public {
        DevStampBadgeVerifier.Document memory document = createDocument();

        // Log the document contents
        console2.log("Document contents:");
        console2.log("context:", document.context[0], document.context[1]);
        console2.log("credentialSubject.hash:", document.credentialSubject.hash);
        console2.log("credentialSubject.id:", document.credentialSubject.id);
        console2.log("credentialSubject.provider:", document.credentialSubject.provider);
        console2.log("credentialSubject.context.hash:", document.credentialSubject.context.hash);
        console2.log("credentialSubject.context.provider:", document.credentialSubject.context.provider);
        console2.log("expirationDate:", document.expirationDate);
        console2.log("issuanceDate:", document.issuanceDate);
        console2.log("issuer:", document.issuer);
        console2.log("proof.context:", document.proof.context);
        console2.log("proof.created:", document.proof.created);
        console2.log("proof.proofPurpose:", document.proof.proofPurpose);
        console2.log("proof.proofType:", document.proof.proofType);
        console2.log("proof.verificationMethod:", document.proof.verificationMethod);
        console2.log("documentType:", document.documentType[0]);

        uint8 v = 28;
        bytes32 r = 0x457ef46b3afeb80c756f442a94af37ae212f0a377bce847cdad3d1f0df4d01eb;
        bytes32 s = 0x421122f559f8bc25e41202d763cd7fdb089e4bdef2e8ce852b4653eff5b65f14;

        // Log the signature components
        console2.log("Signature components:");
        console2.log("v:", v);
        console2.logBytes32(r);
        console2.logBytes32(s);

        // Compute the hash of the document
        bytes32 documentHash = verifier.hashDocument(document);
        console2.log("Document hash:");
        console2.logBytes32(documentHash);

        // Recover the signer's address
        address recoveredSigner = ecrecover(documentHash, v, r, s);
        console2.log("Recovered signer:", recoveredSigner);

        // Call the verifyCredential function
        verifier.verifyCredential(document, v, r, s);

        // Add assertions here to check the result of verification
        // For example, you might check an event was emitted, or a state variable was changed
    }
}