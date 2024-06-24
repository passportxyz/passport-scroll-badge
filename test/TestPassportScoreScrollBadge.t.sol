pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/PassportScoreScrollBadge.sol";
import "../src/IGitcoinPassportDecoder.sol";
import {AttestationRequest, AttestationRequestData, EAS} from "@eas/contracts/EAS.sol";

contract TestPassportScoreScrollBadge is Test {
    PassportScoreScrollBadge passportScoreScrollBadge;
    EAS eas;

    address constant mockDecoder = 0x1234567890123456789012345678901234567890;
    address constant mockAttester = 0x1357246801357246801357246801357246801357;

    address constant resolver = 0x8b3ad69605E4D10637Bbb8Ae2bdc940Ae001D980;
    address constant easAddress = 0xC47300428b6AD2c7D03BB76D05A176058b47E6B0;
    bytes32 constant schema =
        0xba4934720e4c7fc2978acd7c8b4e9cb72288e72f835bd19b2eb4cac99d79d220;

    address constant user = 0x96DB2c6D93A8a12089f7a6EdA5464e967308AdEd;

    function setUp() public {
        uint256[] memory levelsThresholds = new uint256[](3);
        levelsThresholds[0] = 0;
        levelsThresholds[1] = 20;
        levelsThresholds[2] = 30;

        string[] memory badgeLevelImageURIs = new string[](4);
        badgeLevelImageURIs[0] = "URIdefault";
        badgeLevelImageURIs[1] = "URIlevel1";
        badgeLevelImageURIs[2] = "URIlevel2";
        badgeLevelImageURIs[3] = "URIlevel3";

        passportScoreScrollBadge = new PassportScoreScrollBadge(
            resolver,
            mockDecoder,
            levelsThresholds,
            badgeLevelImageURIs
        );
        passportScoreScrollBadge.toggleAttester(mockAttester, true);

        eas = EAS(easAddress);
    }

    function test_issueLevel2() public {
        vm.mockCall(
            mockDecoder,
            abi.encodeWithSelector(
                IGitcoinPassportDecoder.getScore.selector,
                user
            ),
            abi.encode(uint256(25))
        );

        bytes memory data = abi.encode(passportScoreScrollBadge, bytes("0x"));
        AttestationRequestData memory attestation = AttestationRequestData({
            recipient: user,
            expirationTime: 0,
            revocable: false,
            refUID: 0,
            data: data,
            value: 0
        });
        vm.prank(mockAttester);
        bytes32 uid = eas.attest(
            AttestationRequest({schema: schema, data: attestation})
        );

        assertEq(passportScoreScrollBadge.badgeLevel(uid), 2);

        string memory tokenUriJson = Base64.encode(
            abi.encodePacked(
                '{"name":"',
                abi.encode("Passport Score Level #", Strings.toString(uint256(2))),
                '", "description":"',
                "Passport Score Badge",
                ', "image": "',
                "URIlevel2",
                '"}'
            )
        );

        assertEq(
            passportScoreScrollBadge.badgeTokenURI(uid),
            string(
                abi.encodePacked("data:application/json;base64,", tokenUriJson)
            )
        );
    }

    function test_issueLevel1() public {
        vm.mockCall(
            mockDecoder,
            abi.encodeWithSelector(
                IGitcoinPassportDecoder.getScore.selector,
                user
            ),
            abi.encode(uint256(15))
        );

        bytes memory data = abi.encode(passportScoreScrollBadge, bytes("0x"));
        AttestationRequestData memory attestation = AttestationRequestData({
            recipient: user,
            expirationTime: 0,
            revocable: false,
            refUID: 0,
            data: data,
            value: 0
        });
        vm.prank(mockAttester);
        bytes32 uid = eas.attest(
            AttestationRequest({schema: schema, data: attestation})
        );

        assertEq(passportScoreScrollBadge.badgeLevel(uid), 1);
    }

    function test_issueLevel1_0score() public {
        vm.mockCall(
            mockDecoder,
            abi.encodeWithSelector(
                IGitcoinPassportDecoder.getScore.selector,
                user
            ),
            abi.encode(uint256(0))
        );

        bytes memory data = abi.encode(passportScoreScrollBadge, bytes("0x"));
        AttestationRequestData memory attestation = AttestationRequestData({
            recipient: user,
            expirationTime: 0,
            revocable: false,
            refUID: 0,
            data: data,
            value: 0
        });
        vm.prank(mockAttester);
        bytes32 uid = eas.attest(
            AttestationRequest({schema: schema, data: attestation})
        );

        assertEq(passportScoreScrollBadge.badgeLevel(uid), 1);
    }
}
