// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/PassportScoreScrollBadge.sol";

contract DeployPassportScoreScrollBadge is Script {
    address constant resolver = 0x8b3ad69605E4D10637Bbb8Ae2bdc940Ae001D980;
    address constant decoder = 0x90E2C4472Df225e8D31f44725B75FFaA244d5D33;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        uint256[] memory levelsThresholds = new uint256[](5);
        levelsThresholds[0] = 20;
        levelsThresholds[1] = 30;
        levelsThresholds[2] = 40;
        levelsThresholds[3] = 50;
        levelsThresholds[4] = 60;

        string[] memory badgeLevelImageURIs = new string[](6);
        badgeLevelImageURIs[0] = "https://github.com/gitcoinco/passport/blob/93889216df77f83470b948f5c8b3f48c3b0492b4/app/public/scrollBadgeImages/60%2B.png";
        badgeLevelImageURIs[1] = "https://github.com/gitcoinco/passport/blob/93889216df77f83470b948f5c8b3f48c3b0492b4/app/public/scrollBadgeImages/20-29.png";
        badgeLevelImageURIs[2] = "https://github.com/gitcoinco/passport/blob/93889216df77f83470b948f5c8b3f48c3b0492b4/app/public/scrollBadgeImages/30-39.png";
        badgeLevelImageURIs[3] = "https://github.com/gitcoinco/passport/blob/93889216df77f83470b948f5c8b3f48c3b0492b4/app/public/scrollBadgeImages/40-49.png";
        badgeLevelImageURIs[4] = "https://github.com/gitcoinco/passport/blob/93889216df77f83470b948f5c8b3f48c3b0492b4/app/public/scrollBadgeImages/50-59.png";
        badgeLevelImageURIs[5] = "https://github.com/gitcoinco/passport/blob/93889216df77f83470b948f5c8b3f48c3b0492b4/app/public/scrollBadgeImages/60%2B.png";

        PassportScoreScrollBadge badge = new PassportScoreScrollBadge(
            resolver,
            decoder
        );

        badge.setLevelThresholds(levelsThresholds);
        badge.setBadgeLevelImageURIs(badgeLevelImageURIs);

        vm.stopBroadcast();
    }
}

