pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "src/PassportDevZKBadge.sol";
import "src/PassportScoreScrollBadge.sol";
import "src/AttesterProxy.sol";
import {AttestationRequest, AttestationRequestData, EAS, Signature} from "@eas/contracts/EAS.sol";
import {Unauthorized} from "canvas-contracts/src/Errors.sol";
import "forge-std/console.sol";

contract TestPassportDevZKBadge is Test {
    PassportDevZKBadge zkBadge;
    AttesterProxy attesterProxy;

    EAS eas;

    address constant mockDecoder = 0x1234567890123456789012345678901234567890;

    address constant resolver = 0x8b3ad69605E4D10637Bbb8Ae2bdc940Ae001D980;
    address constant gitcoinAttester = 0xCc90105D4A2aa067ee768120AdA19886021dF422;
    address constant easAddress = 0xC47300428b6AD2c7D03BB76D05A176058b47E6B0;

    bytes32 constant schema = 0xba4934720e4c7fc2978acd7c8b4e9cb72288e72f835bd19b2eb4cac99d79d220;

    address constant user = 0x5F8eeFb88c2B97ebdC93fabE193fC39Bd9Da2F86;

    function setUp() public {
        IEAS easInterface = IEAS(easAddress);
        zkBadge = new PassportDevZKBadge(resolver);

        string[] memory badgeLevelImageURIs = new string[](6);
        badgeLevelImageURIs[1] = "URIlevel1";
        badgeLevelImageURIs[2] = "URIlevel2";
        badgeLevelImageURIs[3] = "URIlevel3";
        badgeLevelImageURIs[4] = "URIlevel4";
        badgeLevelImageURIs[5] = "URIlevel5";

        // TBD needs updated
        string[] memory descriptions = new string[](6);
        descriptions[1] = "description1";
        descriptions[2] = "description2";
        descriptions[3] = "description3";
        descriptions[4] = "description4";
        descriptions[5] = "description5";

        // TBD needs updated
        string[] memory names = new string[](6);
        names[1] = "Passport ZK Badge - Level 1";
        names[2] = "Passport ZK Badge - Level 2";
        names[3] = "Passport ZK Badge - Level 3";
        names[4] = "Passport ZK Badge - Level 4";
        names[5] = "Passport ZK Badge - Level 5";

        zkBadge.setBadgeLevelImageURIs(badgeLevelImageURIs);
        zkBadge.setBadgeLevelDescriptions(descriptions);
        zkBadge.setBadgeLevelNames(names);

        zkBadge.toggleAttester(address(gitcoinAttester), true);

        eas = EAS(easAddress);
    }

    function test_issueLevel1_gitcoinAttestation() public {
        uint256 currentLevel = 1;
        bytes memory currentLevelBytes = abi.encode(currentLevel);
        bytes memory data = abi.encode(address(zkBadge), currentLevelBytes);

        AttestationRequestData memory attestation = AttestationRequestData({
            recipient: user,
            expirationTime: 0,
            revocable: false,
            refUID: 0,
            data: data,
            value: 0
        });

        vm.prank(gitcoinAttester);
        bytes32 uid = eas.attest(AttestationRequest({schema: schema, data: attestation}));

        assertEq(zkBadge.badgeLevel(uid), 1);

        string memory uri = zkBadge.badgeTokenURI(uid);
        console.log(uri, "uri");

        // assertEq(
        //     uri,
        //     string.concat(
        //     "data:application/json;base64,",
        //         string(Base64.encode(
        //             '{"name":"Passport ZK Badge - Level 1", "description":""description1", "image": "URIlevel1"}'
        //         )))
        // );
    }

    function test_upgrade() public {
        uint256 currentLevel = 1;
        bytes memory currentLevelBytes = abi.encode(currentLevel);
        bytes memory data = abi.encode(address(zkBadge), currentLevelBytes);

        AttestationRequestData memory attestation = AttestationRequestData({
            recipient: user,
            expirationTime: 0,
            revocable: false,
            refUID: 0,
            data: data,
            value: 0
        });

        vm.prank(gitcoinAttester);
        bytes32 uid = eas.attest(AttestationRequest({schema: schema, data: attestation}));

        assertEq(zkBadge.badgeLevel(uid), 1);

        uint256 newLevel = 2;
        bytes memory newLevelBytes = abi.encode(newLevel);
        bytes memory newData = abi.encode(address(zkBadge), newLevelBytes);

        AttestationRequestData memory newAttestation = AttestationRequestData({
            recipient: user,
            expirationTime: 0,
            revocable: false,
            refUID: uid,
            data: newData,
            value: 0
        });

        vm.prank(gitcoinAttester);
        bytes32 newUid = eas.attest(AttestationRequest({schema: schema, data: newAttestation}));

        assertEq(zkBadge.badgeLevel(newUid), 2);
    }
}
