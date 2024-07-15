pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "src/PassportScoreScrollBadge.sol";
import "src/IGitcoinPassportDecoder.sol";
import "src/AttesterProxy.sol";
import {DelegatedProxyAttestationRequest} from "@eas/contracts/eip712/proxy/EIP712Proxy.sol";
import {AttestationRequest, AttestationRequestData, EAS, Signature} from "@eas/contracts/EAS.sol";
import {Unauthorized} from "@canvas/Errors.sol";
import "forge-std/console.sol";

contract TestPassportScoreScrollBadge is Test {
    PassportScoreScrollBadge passportScoreScrollBadge;
    AttesterProxy attesterProxy;
    EAS eas;

    address constant mockDecoder = 0x1234567890123456789012345678901234567890;

    address constant resolver = 0x8b3ad69605E4D10637Bbb8Ae2bdc940Ae001D980;
    address constant easAddress = 0xC47300428b6AD2c7D03BB76D05A176058b47E6B0;
    bytes32 constant schema =
        0xba4934720e4c7fc2978acd7c8b4e9cb72288e72f835bd19b2eb4cac99d79d220;

    address constant issuer = 0x804233b96cbd6d81efeb6517347177ef7bD488ED;

    address constant user = 0x96DB2c6D93A8a12089f7a6EdA5464e967308AdEd;

    function setUp() public {
        passportScoreScrollBadge = new PassportScoreScrollBadge(
            resolver,
            mockDecoder
        );
        IEAS easInterface = IEAS(easAddress);
        attesterProxy = new AttesterProxy(easInterface);

        uint256[] memory levelsThresholds = new uint256[](3);
        levelsThresholds[0] = 200000;
        levelsThresholds[1] = 300000;
        levelsThresholds[2] = 400000;

        string[] memory badgeLevelImageURIs = new string[](4);
        badgeLevelImageURIs[0] = "URIdefault";
        badgeLevelImageURIs[1] = "URIlevel1";
        badgeLevelImageURIs[2] = "URIlevel2";
        badgeLevelImageURIs[3] = "URIlevel3";

        string[] memory descriptions = new string[](6);
        descriptions[0] = "This badge is for Scrollers who have a Passport score above 20, and have minted an onchain attestation to the Scroll network. Minting this badge informs everyone in the Scroll ecosystem that you're a real human!";
        descriptions[1] = "This badge is for Scrollers who have a Passport score above 20, and have minted an onchain attestation to the Scroll network. Minting this badge informs everyone in the Scroll ecosystem that you're a real human! Increase your onchain Humanity Score to upgrade your badge.";
        descriptions[2] = "This badge is for Scrollers who have a Passport score above 30, and have minted an onchain attestation to the Scroll network. Minting this badge informs everyone in the Scroll ecosystem that you're a real human! Increase your onchain Humanity Score to upgrade your badge.";
        descriptions[3] = "This badge is for Scrollers who have a Passport score above 40, and have minted an onchain attestation to the Scroll network. Minting this badge informs everyone in the Scroll ecosystem that you're a real human! Increase your onchain Humanity Score to upgrade your badge.";
        descriptions[4] = "This badge is for Scrollers who have a Passport score above 50, and have minted an onchain attestation to the Scroll network. Minting this badge informs everyone in the Scroll ecosystem that you're a real human! Increase your onchain Humanity Score to upgrade your badge.";
        descriptions[5] = "This badge is for Scrollers who have a Passport score above 60, and have minted an onchain attestation to the Scroll network. Minting this badge informs everyone in the Scroll ecosystem that you're a real human! This is the highest level badge.";

        string[] memory names = new string[](6);
        names[0] = "Unique Humanity Score";
        names[1] = "Unique Humanity Score - Level 1";
        names[2] = "Unique Humanity Score - Level 2";
        names[3] = "Unique Humanity Score - Level 3";
        names[4] = "Unique Humanity Score - Level 4";
        names[5] = "Unique Humanity Score - Level 5";

        passportScoreScrollBadge.setLevelThresholds(levelsThresholds);
        passportScoreScrollBadge.setBadgeLevelImageURIs(badgeLevelImageURIs);
        passportScoreScrollBadge.setBadgeLevelDescriptions(descriptions);
        passportScoreScrollBadge.setBadgeLevelNames(names);

        passportScoreScrollBadge.toggleAttester(address(attesterProxy), true);

        eas = EAS(easAddress);
    }

    function test_issueLevel2_delegatedAttestation() public {
        vm.mockCall(
            mockDecoder,
            abi.encodeWithSelector(
                IGitcoinPassportDecoder.getScore.selector,
                user
            ),
            abi.encode(uint256(350000))
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

        // We should actually be doing this, but it's taking forever to figure out how to create the signature
        // DelegatedProxyAttestationRequest memory easRequest = DelegatedProxyAttestationRequest({
        //     schema: schema,
        //     data: attestation,
        //     attester: issuer,
        //     deadline: block.timestamp + 3000
        // });

        vm.prank(address(attesterProxy));
        bytes32 uid = eas.attest(
            AttestationRequest({schema: schema, data: attestation})
        );

        assertEq(passportScoreScrollBadge.badgeLevel(uid), 2);

        string memory uri = passportScoreScrollBadge.badgeTokenURI(uid);

        assertEq(
            uri,
            string.concat(
            "data:application/json;base64,",
                string(Base64.encode(
                    '{"name":"Unique Humanity Score - Level 2", "description":"This badge is for Scrollers who have a Passport score above 30, and have minted an onchain attestation to the Scroll network. Minting this badge informs everyone in the Scroll ecosystem that you\'re a real human! Increase your onchain Humanity Score to upgrade your badge.", "image": "URIlevel2"}'
                )))
        );
    }

    function test_issueLevel1() public {
        vm.mockCall(
            mockDecoder,
            abi.encodeWithSelector(
                IGitcoinPassportDecoder.getScore.selector,
                user
            ),
            abi.encode(uint256(250000))
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
        vm.prank(address(attesterProxy));
        bytes32 uid = eas.attest(
            AttestationRequest({schema: schema, data: attestation})
        );

        assertEq(passportScoreScrollBadge.badgeLevel(uid), 1);
    }

    function test_issueLevel1EdgeCase() public {
        vm.mockCall(
            mockDecoder,
            abi.encodeWithSelector(
                IGitcoinPassportDecoder.getScore.selector,
                user
            ),
            abi.encode(uint256(200000))
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
        vm.prank(address(attesterProxy));
        bytes32 uid = eas.attest(
            AttestationRequest({schema: schema, data: attestation})
        );

        assertEq(passportScoreScrollBadge.badgeLevel(uid), 1);
    }

    function test_RevertIf_scoreTooLow() public {
        vm.mockCall(
            mockDecoder,
            abi.encodeWithSelector(
                IGitcoinPassportDecoder.getScore.selector,
                user
            ),
            abi.encode(uint256(50000))
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
        vm.prank(address(attesterProxy));
        vm.expectRevert(Unauthorized.selector);
        eas.attest(AttestationRequest({schema: schema, data: attestation}));
    }

    function test_RevertIf_nonOwnerTriesToUpdateThresholds() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(user);
        passportScoreScrollBadge.setLevelThresholds(new uint256[](3));
    }

    function test_upgrade() public {
        vm.mockCall(
            mockDecoder,
            abi.encodeWithSelector(
                IGitcoinPassportDecoder.getScore.selector,
                user
            ),
            abi.encode(uint256(250000))
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
        vm.prank(address(attesterProxy));
        bytes32 uid = eas.attest(
            AttestationRequest({schema: schema, data: attestation})
        );

        assertEq(passportScoreScrollBadge.badgeLevel(uid), 1);

        vm.mockCall(
            mockDecoder,
            abi.encodeWithSelector(
                IGitcoinPassportDecoder.getScore.selector,
                user
            ),
            abi.encode(uint256(350000))
        );

        vm.prank(user);
        passportScoreScrollBadge.upgrade(uid);

        assertEq(passportScoreScrollBadge.badgeLevel(uid), 2);
    }

    function test_tokenURILevel0() public view {
        bytes32 uid = 0x0;
        string memory uri = passportScoreScrollBadge.badgeTokenURI(uid);

        assertEq(
            uri,
            string.concat(
            "data:application/json;base64,",
                string(Base64.encode(
                    '{"name":"Unique Humanity Score", "description":"This badge is for Scrollers who have a Passport score above 20, and have minted an onchain attestation to the Scroll network. Minting this badge informs everyone in the Scroll ecosystem that you\'re a real human!", "image": "URIdefault"}'
                )))
        );
    }
}
