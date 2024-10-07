pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "src/PassportDevZKBadge.sol";
import "src/PassportScoreScrollBadge.sol";
import "src/AttesterProxy.sol";
import {AttestationRequest, AttestationRequestData, EAS, Signature} from "@eas/contracts/EAS.sol";
import {Unauthorized} from "canvas-contracts/src/Errors.sol";
import "forge-std/console.sol";
import {SchemaResolver, ISchemaResolver} from "@eas/contracts/resolver/SchemaResolver.sol";

contract TestPassportDevZKBadge is Test {
    PassportDevZKBadge zkBadge;
    AttesterProxy attesterProxy;
    EAS eas;

    bytes32 upgradeSchema;

    address constant mockDecoder = 0x1234567890123456789012345678901234567890;

    address constant resolver = 0x8b3ad69605E4D10637Bbb8Ae2bdc940Ae001D980;
    address constant gitcoinAttester = 0xCc90105D4A2aa067ee768120AdA19886021dF422;
    address constant easAddress = 0xC47300428b6AD2c7D03BB76D05A176058b47E6B0;

    bytes32 constant schema = 0xba4934720e4c7fc2978acd7c8b4e9cb72288e72f835bd19b2eb4cac99d79d220;

    address constant user = 0x5F8eeFb88c2B97ebdC93fabE193fC39Bd9Da2F86;
    address constant user2 = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;

    string constant defaultProviderHash = "GithubGuru";

    function setUp() public {
        IEAS easInterface = IEAS(easAddress);

        zkBadge = new PassportDevZKBadge(resolver, easAddress);

        upgradeSchema = zkBadge.upgradeSchema();

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

        zkBadge.setEASAddress(easAddress);
    }

    function encodeData(uint256 currentLevel, string[] memory providerIds) public view returns (bytes memory) {
        bytes32[] memory providerIdHashes = new bytes32[](providerIds.length);
        
        for (uint i = 0; i < providerIds.length; i++) {
            providerIdHashes[i] = keccak256(abi.encodePacked(providerIds[i]));
        }
        
        bytes memory payload = abi.encode(currentLevel, providerIdHashes);
        return abi.encode(address(zkBadge), payload);
    }

    function test_issueLevel1_gitcoinAttestation() public {
        uint256 currentLevel = 1;
        string[] memory providerIdHashes = new string[](1);

        providerIdHashes[0] = defaultProviderHash;

        bytes memory data = encodeData(currentLevel, providerIdHashes);

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

        assertEq(zkBadge.badgeLevel(user), 1);

        string memory uri = zkBadge.badgeTokenURI(uid);

        assertEq(
            uri,
            string.concat(
                "data:application/json;base64,",
                string(
                    Base64.encode(
                        '{"name":"Passport ZK Badge - Level 1", "description":"description1", "image": "URIlevel1"}'
                    )
                )
            )
        );
    }

    function test_upgrade_succeeds() public {
        uint256 currentLevel = 1;
        string[] memory providerIdHashes = new string[](1);

        providerIdHashes[0] = defaultProviderHash;
        bytes memory data = encodeData(currentLevel, providerIdHashes);

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

        assertEq(zkBadge.canUpgrade(uid), false);
        

        assertEq(zkBadge.badgeLevel(user), 1);

        uint256 newLevel = 2;

        string[] memory providerIdHashesUpdated = new string[](1);
        providerIdHashesUpdated[0] = "GithubGuruNumber2";
        bytes memory newData = encodeData(newLevel, providerIdHashesUpdated);

        AttestationRequestData memory newAttestation = AttestationRequestData({
            recipient: user,
            expirationTime: 0,
            revocable: false,
            refUID: uid,
            data: newData,
            value: 0
        });

        vm.prank(gitcoinAttester);
        bytes32 newUid = eas.attest(AttestationRequest({schema: upgradeSchema, data: newAttestation}));

        assertEq(zkBadge.canUpgrade(newUid), false);

        assertEq(zkBadge.badgeLevel(user), 2);
    }

    function test_tx_reverts_if_same_hash_is_used_across_addresses() public {
        uint256 currentLevel = 1;
        string[] memory providerIdHashes = new string[](1);
        providerIdHashes[0] = defaultProviderHash;
        bytes memory data = encodeData(currentLevel, providerIdHashes);

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

        assertEq(zkBadge.badgeLevel(user), 1);

        uint256 currentLevelSecondAddress = 1;
        bytes memory dataSecondAddress = encodeData(currentLevel, providerIdHashes);

        AttestationRequestData memory attestation2 = AttestationRequestData({
            recipient: user2,
            expirationTime: 0,
            revocable: false,
            refUID: 0,
            data: dataSecondAddress,
            value: 0
        });

        vm.expectRevert();
        vm.prank(gitcoinAttester);
        eas.attest(AttestationRequest({schema: schema, data: attestation2}));
    }

    function test_unauthorized_upgrade() public {
        uint256 newLevel = 2;
        string[] memory providerIdHashes = new string[](1);
        providerIdHashes[0] = defaultProviderHash;
        bytes memory data = encodeData(newLevel, providerIdHashes);

        AttestationRequestData memory newAttestation = AttestationRequestData({
            recipient: user2,
            expirationTime: 0,
            revocable: false,
            refUID: 0,
            data: data,
            value: 0
        });

        vm.expectRevert();
        vm.prank(user);
        eas.attest(AttestationRequest({schema: upgradeSchema, data: newAttestation}));
    }

    function test_issueLevel2_gitcoinAttestation() public {
        uint256 currentLevel = 2;
        string[] memory providerIdHashes = new string[](1);
        providerIdHashes[0] = defaultProviderHash;
        bytes memory data = encodeData(currentLevel, providerIdHashes);

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

        assertEq(zkBadge.badgeLevel(user), 2);

        string memory uri = zkBadge.badgeTokenURI(uid);

        assertEq(
            uri,
            string.concat(
                "data:application/json;base64,",
                string(
                    Base64.encode(
                        '{"name":"Passport ZK Badge - Level 2", "description":"description2", "image": "URIlevel2"}'
                    )
                )
            )
        );
    }

    function test_issueLevel1EdgeCase() public {
        uint256 currentLevel = 1;
        string[] memory providerIdHashes = new string[](1);
        providerIdHashes[0] = defaultProviderHash;
        bytes memory data = encodeData(currentLevel, providerIdHashes);

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

        assertEq(zkBadge.badgeLevel(user), 1);
    }

    function test_RevertIf_scoreTooLow() public {
        uint256 currentLevel = 0;
        string[] memory providerIdHashes = new string[](1);
        providerIdHashes[0] = defaultProviderHash;
        bytes memory data = encodeData(currentLevel, providerIdHashes);

        AttestationRequestData memory attestation = AttestationRequestData({
            recipient: user,
            expirationTime: 0,
            revocable: false,
            refUID: 0,
            data: data,
            value: 0
        });

        vm.prank(gitcoinAttester);
        vm.expectRevert(Unauthorized.selector);
        eas.attest(AttestationRequest({schema: schema, data: attestation}));
    }

    function test_RevertIf_nonOwnerTriesToUpdateThresholds() public {
        string[] memory newURIs = new string[](6);
        vm.prank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        zkBadge.setBadgeLevelImageURIs(newURIs);
    }

    function test_tokenURILevel0() public {
        // string memory uri = zkBadge.badgeTokenURI(address(0));

        // Uncomment and update the following assertion once the exact URI format is confirmed
        // assertEq(
        //     uri,
        //     string.concat(
        //         "data:application/json;base64,",
        //         string(Base64.encode(
        //             '{"name":"Passport ZK Badge", "description":"Default description", "image": "URIdefault"}'
        //         ))
        //     )
        // );
    }
}
