// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/test.sol";
import {SigUtils} from "./utils/SigUtils.sol";
import "src/DevStampBadgeVerifier.sol";
// import {MockERC20} from "./utils/MockERC20.sol";

contract DevStampBadgeVerifierTest is Test {
    DevStampBadgeVerifier internal verifier;
    SigUtils internal sigUtils;

    uint256 internal ownerPrivateKey;
    uint256 internal spenderPrivateKey;

    address internal owner;
    address internal spender;

    function setUp() public {
        verifier = new DevStampBadgeVerifier();
        sigUtils = new SigUtils(verifier.computeDomainSeparator());

        ownerPrivateKey = 0xA11CE;
        spenderPrivateKey = 0xB0B;

        owner = vm.addr(ownerPrivateKey);
        spender = vm.addr(spenderPrivateKey);

        // token.mint(owner, 1e18);
    }

    function createDocument() public pure returns (Document memory) {
        // Initialize _context array
        string[] memory contextArray = new string[](2);
        contextArray[0] = "https://www.w3.org/2018/credentials/v1";
        contextArray[1] = "https://w3id.org/vc/status-list/2021/v1";

        // Initialize CredentialSubjectContext
        CredentialSubjectContext memory subjectContext =
            CredentialSubjectContext({_hash: "https://schema.org/Text", provider: "https://schema.org/Text"});

        // Initialize CredentialSubject
        CredentialSubject memory subject = CredentialSubject({
            _hash: "v0.0.0:DuIuMoRGzEw9Is5C/uGkKxqzQBR+0BuUtMPsrFEkstc=",
            id: "did:pkh:eip155:1:0x0636F974D29d947d4946b2091d769ec6D2d415DE",
            provider: "ETHGasSpent#0.25",
            _context: subjectContext
        });

        // Initialize Proof
        Proof memory proofData = Proof({
            _context: "https://w3id.org/security/suites/eip712sig-2021/v1",
            created: "2024-09-27T17:14:37.290Z",
            proofPurpose: "assertionMethod",
            _type: "EthereumEip712Signature2021",
            verificationMethod: "did:ethr:0xd6f8d6ca86aa01e551a311d670a0d1bd8577e5fb#controller"
        });

        // Initialize _type array
        string[] memory typeArray = new string[](1);
        typeArray[0] = "VerifiableCredential";

        // Initialize Document
        Document memory doc = Document({
            _context: contextArray,
            credentialSubject: subject,
            expirationDate: "2024-12-26T17:14:37.283Z",
            issuanceDate: "2024-09-27T17:14:37.283Z",
            issuer: "did:ethr:0xd6f8d6ca86aa01e551a311d670a0d1bd8577e5fb",
            proof: proofData,
            _type: typeArray
        });

        return doc;
    }

    function testCredentialVerification() public {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/test/utils/normalizedCredential.json");
        string memory json = vm.readFile(path);
        bytes memory data = vm.parseJson(json);

        // Document memory document = abi.decode(data, (Document));

        Document memory document = createDocument();

        // Generated from ethers.utils.splitSignature("0x7c9dfc005e0800e7745eafdfb5f774654c9b7245658021d546e5871e7d5f05bd6a0342c7b195fa01e907219cfc6aac71ac6c7fc11e614aa327bebd5a323eaca51b")

        uint8 v = 27;
        bytes32 r = 0x8994712895556c7916b52ede01f9a1f0b71d73e3dc6cd1318be1a56361a77912;
        bytes32 s = 0x58352eac95e2507281cdf26ec891690952848b63006c2adeda30c217765f72a9;

        verifier.verifyCredential(document, v, r, s);

        // assertEq(token.allowance(owner, spender), 1e18);
        // assertEq(token.nonces(owner), 1);
    }

//     {
//   "Proof": [
//     {
//       "name": "@context",
//       "type": "string"
//     },
//     {
//       "name": "created",
//       "type": "string"
//     },
//     {
//       "name": "proofPurpose",
//       "type": "string"
//     },
//     {
//       "name": "type",
//       "type": "string"
//     },
//     {
//       "name": "verificationMethod",
//       "type": "string"
//     }
//   ],
//   "@context": [
//     {
//       "name": "hash",
//       "type": "string"
//     },
//     {
//       "name": "provider",
//       "type": "string"
//     }
//   ],
//   "Document": [
//     {
//       "name": "@context",
//       "type": "string[]"
//     },
//     {
//       "name": "credentialSubject",
//       "type": "CredentialSubject"
//     },
//     {
//       "name": "expirationDate",
//       "type": "string"
//     },
//     {
//       "name": "issuanceDate",
//       "type": "string"
//     },
//     {
//       "name": "issuer",
//       "type": "string"
//     },
//     {
//       "name": "proof",
//       "type": "Proof"
//     },
//     {
//       "name": "type",
//       "type": "string[]"
//     }
//   ],
//   "EIP712Domain": [
//     {
//       "name": "name",
//       "type": "string"
//     }
//   ],
//   "CredentialSubject": [
//     {
//       "name": "@context",
//       "type": "@context"
//     },
//     {
//       "name": "hash",
//       "type": "string"
//     },
//     {
//       "name": "id",
//       "type": "string"
//     },
//     {
//       "name": "provider",
//       "type": "string"
//     }
//   ]
// }
}
