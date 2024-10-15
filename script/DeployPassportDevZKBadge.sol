// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {PassportDevZKBadge} from "../src/PassportDevZKBadge.sol";

contract DeployPassportDevZKBadge is Script {
    // Mainnet
    // address constant resolver = 0x4560FECd62B14A463bE44D40fE5Cfd595eEc0113;
    // address constant gitcoinAttester = 0x39571bBD5a4c5d1a5184004c63F45FE426dB85Ea;
    // address constant easAddress = 0xC47300428b6AD2c7D03BB76D05A176058b47E6B0;

    // Sepolia
    address constant resolver = 0xd2270b3540FD2220Fa1025414e1625af8B0dd8f3;
    address constant gitcoinAttester = 0xCc90105D4A2aa067ee768120AdA19886021dF422;
    address constant easAddress = 0xaEF4103A04090071165F78D45D83A0C0782c2B2a;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        console.log("Deployer: ", vm.addr(deployerPrivateKey));

        // Set level thresholds (example values, adjust as needed)
        uint256[] memory levelThresholds = new uint256[](3);
        levelThresholds[0] = 100;
        levelThresholds[1] = 200;
        levelThresholds[2] = 300;

        // Set 1: ZK Rollups
        string[] memory imageURIs1 = new string[](4);
        imageURIs1[0] = "https://example.com/zk-rollups/no-score.png";
        imageURIs1[1] = "https://raw.githubusercontent.com/passportxyz/passport/10533495e270f7f0706e16d0d7c8ff0e68aa6c34/app/public/assets/zkInfraTalent1.svg";
        imageURIs1[2] = "https://raw.githubusercontent.com/passportxyz/passport/10533495e270f7f0706e16d0d7c8ff0e68aa6c34/app/public/assets/zkInfraTalent2.svg";
        imageURIs1[3] = "https://raw.githubusercontent.com/passportxyz/passport/10533495e270f7f0706e16d0d7c8ff0e68aa6c34/app/public/assets/zkInfraTalent3.svg";

        string[] memory names1 = new string[](4);
        names1[0] = "No Score";
        names1[1] = "ZK Rollup Talent";
        names1[2] = "ZK Rollup Talent";
        names1[3] = "ZK Rollup Talent";

        string[] memory descriptions1 = new string[](4);
        descriptions1[0] = "No contributions yet";
        descriptions1[1] = "Contributed to ZK rollups projects";
        descriptions1[2] = "Contributed to ZK rollups projects";
        descriptions1[3] = "Contributed to ZK rollups projects";

        // Set 2: ZK Games
        string[] memory imageURIs2 = new string[](4);
        imageURIs2[0] = "https://example.com/zk-rollups/no-score.png";
        imageURIs2[1] = "https://raw.githubusercontent.com/passportxyz/passport/10533495e270f7f0706e16d0d7c8ff0e68aa6c34/app/public/assets/zkPrivacyTalent1.svg";
        imageURIs2[2] = "https://raw.githubusercontent.com/passportxyz/passport/10533495e270f7f0706e16d0d7c8ff0e68aa6c34/app/public/assets/zkPrivacyTalent2.svg";
        imageURIs2[3] = "https://raw.githubusercontent.com/passportxyz/passport/10533495e270f7f0706e16d0d7c8ff0e68aa6c34/app/public/assets/zkPrivacyTalent3.svg";

        string[] memory names2 = new string[](4);
        names2[0] = "No Score";
        names2[1] = "zk Infra Talent";
        names2[2] = "zk Infra Talentr";
        names2[3] = "zk Infra Talent";

        string[] memory descriptions2 = new string[](4);
        descriptions2[0] = "No contributions yet";
        descriptions2[1] = "Contributed to ZK Infra projects";
        descriptions2[2] = "Contributed to ZK Infra projects";
        descriptions2[3] = "Contributed to ZK Infra projects";

        // Set 3: ZK Privacy
        string[] memory imageURIs3 = new string[](4);
        imageURIs3[0] = "https://example.com/zk-rollups/no-score.png";
        imageURIs3[1] = "https://raw.githubusercontent.com/passportxyz/passport/10533495e270f7f0706e16d0d7c8ff0e68aa6c34/app/public/assets/zkRollupTalent1.svg";
        imageURIs3[2] = "https://raw.githubusercontent.com/passportxyz/passport/10533495e270f7f0706e16d0d7c8ff0e68aa6c34/app/public/assets/zkRollupTalent2.svg";
        imageURIs3[3] = "https://raw.githubusercontent.com/passportxyz/passport/10533495e270f7f0706e16d0d7c8ff0e68aa6c34/app/public/assets/zkRollupTalent3.svg";

        string[] memory names3 = new string[](4);
        names3[0] = "No Score";
        names3[1] = "zk Privacy Talent";
        names3[2] = "zk Privacy Talent";
        names3[3] = "zk Privacy Talent";

        string[] memory descriptions3 = new string[](4);
        descriptions3[0] = "No contributions yet";
        descriptions3[1] = "Contributed to ZK privacy projects";
        descriptions3[2] = "Contributed to ZK privacy projects";
        descriptions3[3] = "Contributed to ZK privacy projects";

        // Deploy ZK Rollups Badge
        PassportDevZKBadge badgeRollups = new PassportDevZKBadge(resolver, easAddress);
        badgeRollups.toggleAttester(gitcoinAttester, true);
        badgeRollups.setEASAddress(easAddress);
        badgeRollups.setLevelThresholds(levelThresholds);
        badgeRollups.setBadgeLevelImageURIs(imageURIs1);
        badgeRollups.setBadgeLevelNames(names1);
        badgeRollups.setBadgeLevelDescriptions(descriptions1);

        // Deploy ZK Games Badge
        PassportDevZKBadge badgeInfra = new PassportDevZKBadge(resolver, easAddress);
        badgeInfra.toggleAttester(gitcoinAttester, true);
        badgeInfra.setEASAddress(easAddress);
        badgeInfra.setLevelThresholds(levelThresholds);
        badgeInfra.setBadgeLevelImageURIs(imageURIs2);
        badgeInfra.setBadgeLevelNames(names2);
        badgeInfra.setBadgeLevelDescriptions(descriptions2);

        // // // Deploy ZK Privacy Badge
        PassportDevZKBadge badgePrivacy = new PassportDevZKBadge(resolver, easAddress);
        badgePrivacy.toggleAttester(gitcoinAttester, true);
        badgePrivacy.setEASAddress(easAddress);
        badgePrivacy.setLevelThresholds(levelThresholds);
        badgePrivacy.setBadgeLevelImageURIs(imageURIs3);
        badgePrivacy.setBadgeLevelNames(names3);
        badgePrivacy.setBadgeLevelDescriptions(descriptions3);

        vm.stopBroadcast();

        console.log("PassportDevZKBadge (ZK Rollups) deployed at:", address(badgeRollups));
        console.log("PassportDevZKBadge (ZK Infra) deployed at:", address(badgeGames));
        console.log("PassportDevZKBadge (ZK Privacy) deployed at:", address(badgePrivacy));
    }
}
