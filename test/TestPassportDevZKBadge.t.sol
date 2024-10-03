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

    address constant user = 0xDbf14bc7111e5F9Ed0423Ef8792258b7EBa8764c;

    function setUp() public {
        IEAS easInterface = IEAS(easAddress);
        zkBadge = new PassportDevZKBadge(resolver, mockDecoder);

        uint256[] memory levelsThresholds = new uint256[](5);
        levelsThresholds[0] = 200000;
        levelsThresholds[1] = 300000;
        levelsThresholds[2] = 400000;
        levelsThresholds[3] = 500000;
        levelsThresholds[4] = 600000;

        string[] memory badgeLevelImageURIs = new string[](6);
        badgeLevelImageURIs[0] = "https://raw.githubusercontent.com/gitcoinco/passport/93889216df77f83470b948f5c8b3f48c3b0492b4/app/public/scrollBadgeImages/60%2B.png";
        badgeLevelImageURIs[1] = "https://raw.githubusercontent.com/gitcoinco/passport/93889216df77f83470b948f5c8b3f48c3b0492b4/app/public/scrollBadgeImages/20-29.png";
        badgeLevelImageURIs[2] = "https://raw.githubusercontent.com/gitcoinco/passport/93889216df77f83470b948f5c8b3f48c3b0492b4/app/public/scrollBadgeImages/30-39.png";
        badgeLevelImageURIs[3] = "https://raw.githubusercontent.com/gitcoinco/passport/93889216df77f83470b948f5c8b3f48c3b0492b4/app/public/scrollBadgeImages/40-49.png";
        badgeLevelImageURIs[4] = "https://raw.githubusercontent.com/gitcoinco/passport/93889216df77f83470b948f5c8b3f48c3b0492b4/app/public/scrollBadgeImages/50-59.png";
        badgeLevelImageURIs[5] = "https://raw.githubusercontent.com/gitcoinco/passport/93889216df77f83470b948f5c8b3f48c3b0492b4/app/public/scrollBadgeImages/60%2B.png";

        // TBD needs updated
        string[] memory descriptions = new string[](6);
        descriptions[0] =
            "This badge is for Devs who have contributed to greater than one open source ZK project. Minting this badge informs everyone in the Scroll ecosystem that you're a ZK dev!";
        descriptions[1] =
            "This badge is for Devs who have contributed to greater than two open source ZK project. Minting this badge informs everyone in the Scroll ecosystem that you're a ZK dev!";
        descriptions[2] =
            "This badge is for Devs who have contributed to greater than three open source ZK project. Minting this badge informs everyone in the Scroll ecosystem that you're a ZK dev!";
        descriptions[3] =
            "This badge is for Devs who have contributed to greater than four open source ZK project. Minting this badge informs everyone in the Scroll ecosystem that you're a ZK dev!";
        descriptions[4] =
            "This badge is for Devs who have contributed to greater than five open source ZK project. Minting this badge informs everyone in the Scroll ecosystem that you're a ZK dev!";
        descriptions[5] =
            "This badge is for Devs who have contributed to greater than six open source ZK project. Minting this badge informs everyone in the Scroll ecosystem that you're a ZK dev!";

        // TBD needs updated
        string[] memory names = new string[](6);
        names[0] = "Passport ZK Badge - Level 0";
        names[1] = "Passport ZK Badge - Level 1";
        names[2] = "Passport ZK Badge - Level 2";
        names[3] = "Passport ZK Badge - Level 3";
        names[4] = "Passport ZK Badge - Level 4";
        names[5] = "Passport ZK Badge - Level 5";
        

        zkBadge.setLevelThresholds(levelsThresholds);
        zkBadge.setBadgeLevelImageURIs(badgeLevelImageURIs);
        zkBadge.setBadgeLevelDescriptions(descriptions);
        zkBadge.setBadgeLevelNames(names);


        zkBadge.toggleAttester(address(gitcoinAttester), true);

        
        eas = EAS(easAddress);
    }

    function test_issueLevel1_gitcoinAttestation() public {
        // vm.mockCall(
        //     mockDecoder,
        //     abi.encodeWithSelector(
        //         IGitcoinPassportDecoder.getScore.selector,
        //         user
        //     ),
        //     abi.encode(uint256(350000))
        // );


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
        bytes32 uid = eas.attest(
            AttestationRequest({schema: schema, data: attestation})
        );
        

        assertEq(zkBadge.badgeLevel(uid), 1);

        // string memory uri = zkBadge.badgeTokenURI(uid);

        // assertEq(
        //     uri,
        //     string.concat(
        //     "data:application/json;base64,",
        //         string(Base64.encode(
        //             '{"name":"Unique Humanity Score - Level 2", "description":"This badge is for Scrollers who have a Passport score above 30, and have minted an onchain attestation to the Scroll network. Minting this badge informs everyone in the Scroll ecosystem that you\'re a real human! Increase your onchain Humanity Score to upgrade your badge.", "image": "URIlevel2"}'
        //         )))
        // );
    }
}
