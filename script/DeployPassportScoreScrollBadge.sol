// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/PassportScoreScrollBadge.sol";

contract DeployPassportScoreScrollBadge is Script {
    // Mainnet
    address constant resolver = 0x8b3ad69605E4D10637Bbb8Ae2bdc940Ae001D980;
    address constant decoder = 0x8A5820030188346cC9532a1dD9FD2EF8d8F464de;
    address constant attesterProxy = 0x39571bBD5a4c5d1a5184004c63F45FE426dB85Ea;

    // Sepolia
    // address constant resolver = 0xd2270b3540FD2220Fa1025414e1625af8B0dd8f3;
    // address constant decoder = 0x2443D22Db6d25D141A1138D80724e3Eee54FD4C2;
    // address constant attesterProxy = 0x2d4E236AB6F9a41b6FDb0ce531D1915900eD3417;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

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

        PassportScoreScrollBadge badge = new PassportScoreScrollBadge(
            resolver,
            decoder
        );

        badge.setLevelThresholds(levelsThresholds);
        badge.setBadgeLevelImageURIs(badgeLevelImageURIs);
        badge.toggleAttester(attesterProxy, true);

        vm.stopBroadcast();
    }
}

