// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {PassportDevZKBadge} from "../src/PassportDevZKBadge.sol";

contract DeployPassportDevZKBadge is Script {
    // Mainnet
    address constant resolver = 0x4560FECd62B14A463bE44D40fE5Cfd595eEc0113;
    address constant gitcoinAttester = 0xCc90105D4A2aa067ee768120AdA19886021dF422;
    address constant easAddress = 0xC47300428b6AD2c7D03BB76D05A176058b47E6B0;

    // Sepolia
    // address constant resolver = 0xd2270b3540FD2220Fa1025414e1625af8B0dd8f3;
    // address constant gitcoinAttester = 0xCc90105D4A2aa067ee768120AdA19886021dF422;
    // address constant easAddress = 0xaEF4103A04090071165F78D45D83A0C0782c2B2a;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        console.log("Deployer: ", vm.addr(deployerPrivateKey));

        // Set level thresholds (example values, adjust as needed)
        uint256[] memory levelThresholds = new uint256[](3);
        levelThresholds[0] = 1;
        levelThresholds[1] = 2;
        levelThresholds[2] = 3;

        // Set 1: ZK Rollups
        

        string[] memory rollupNames = new string[](4);
        rollupNames[0] = "No Score";
        rollupNames[1] = "ZK Rollup Talent";
        rollupNames[2] = "ZK Rollup Talent";
        rollupNames[3] = "ZK Rollup Talent";

        string[] memory rollupDescriptions = new string[](4);
        rollupDescriptions[0] = "No contributions yet";
        rollupDescriptions[1] = "Contributed to ZK rollups projects";
        rollupDescriptions[2] = "Contributed to ZK rollups projects";
        rollupDescriptions[3] = "Contributed to ZK rollups projects";

        string[] memory rollupImageUris = new string[](4);
        rollupImageUris[0] = "";
        rollupImageUris[1] = "https://raw.githubusercontent.com/passportxyz/passport/10533495e270f7f0706e16d0d7c8ff0e68aa6c34/app/public/assets/zkRollupTalent1.svg";
        rollupImageUris[2] = "https://raw.githubusercontent.com/passportxyz/passport/10533495e270f7f0706e16d0d7c8ff0e68aa6c34/app/public/assets/zkRollupTalent2.svg";
        rollupImageUris[3] = "https://raw.githubusercontent.com/passportxyz/passport/10533495e270f7f0706e16d0d7c8ff0e68aa6c34/app/public/assets/zkRollupTalent3.svg";
        

        // Deploy ZK Rollups Badge
        PassportDevZKBadge badgeRollups = new PassportDevZKBadge(resolver, easAddress);
        badgeRollups.toggleAttester(gitcoinAttester, true);
        badgeRollups.setEASAddress(easAddress);
        badgeRollups.setLevelThresholds(levelThresholds);
        badgeRollups.setBadgeLevelImageURIs(rollupImageUris);
        badgeRollups.setBadgeLevelNames(rollupNames);
        badgeRollups.setBadgeLevelDescriptions(rollupDescriptions);

        // Set 2: ZK Infra

        string[] memory infraImageUris = new string[](4);
        infraImageUris[0] = "";
        infraImageUris[1] = "https://raw.githubusercontent.com/passportxyz/passport/10533495e270f7f0706e16d0d7c8ff0e68aa6c34/app/public/assets/zkInfraTalent1.svg";
        infraImageUris[2] = "https://raw.githubusercontent.com/passportxyz/passport/10533495e270f7f0706e16d0d7c8ff0e68aa6c34/app/public/assets/zkInfraTalent2.svg";
        infraImageUris[3] = "https://raw.githubusercontent.com/passportxyz/passport/10533495e270f7f0706e16d0d7c8ff0e68aa6c34/app/public/assets/zkInfraTalent3.svg";

        string[] memory infraNames = new string[](4);
        infraNames[0] = "No Score";
        infraNames[1] = "zk Infra Talent";
        infraNames[2] = "zk Infra Talentr";
        infraNames[3] = "zk Infra Talent";

        string[] memory infraDescriptions = new string[](4);
        infraDescriptions[0] = "No contributions yet";
        infraDescriptions[1] = "Contributed to ZK Infra projects";
        infraDescriptions[2] = "Contributed to ZK Infra projects";
        infraDescriptions[3] = "Contributed to ZK Infra projects";

        // Deploy ZK Infra Badge
        PassportDevZKBadge badgeInfra = new PassportDevZKBadge(resolver, easAddress);
        badgeInfra.toggleAttester(gitcoinAttester, true);
        badgeInfra.setEASAddress(easAddress);
        badgeInfra.setLevelThresholds(levelThresholds);
        badgeInfra.setBadgeLevelImageURIs(infraImageUris);
        badgeInfra.setBadgeLevelNames(infraNames);
        badgeInfra.setBadgeLevelDescriptions(infraDescriptions);

        // Set 3: ZK Privacy
        string[] memory privacyImageUris = new string[](4);
        privacyImageUris[0] = "";
        privacyImageUris[1] = "https://raw.githubusercontent.com/passportxyz/passport/10533495e270f7f0706e16d0d7c8ff0e68aa6c34/app/public/assets/zkPrivacyTalent1.svg";
        privacyImageUris[2] = "https://raw.githubusercontent.com/passportxyz/passport/10533495e270f7f0706e16d0d7c8ff0e68aa6c34/app/public/assets/zkPrivacyTalent2.svg";
        privacyImageUris[3] = "https://raw.githubusercontent.com/passportxyz/passport/10533495e270f7f0706e16d0d7c8ff0e68aa6c34/app/public/assets/zkPrivacyTalent3.svg";

        string[] memory privacyNames = new string[](4);
        privacyNames[0] = "No Score";
        privacyNames[1] = "zk Privacy Talent";
        privacyNames[2] = "zk Privacy Talent";
        privacyNames[3] = "zk Privacy Talent";

        string[] memory privacyDescriptions = new string[](4);
        privacyDescriptions[0] = "No contributions yet";
        privacyDescriptions[1] = "Contributed to ZK privacy projects";
        privacyDescriptions[2] = "Contributed to ZK privacy projects";
        privacyDescriptions[3] = "Contributed to ZK privacy projects";

        // Deploy ZK Privacy Badge
        PassportDevZKBadge badgePrivacy = new PassportDevZKBadge(resolver, easAddress);
        badgePrivacy.toggleAttester(gitcoinAttester, true);
        badgePrivacy.setEASAddress(easAddress);
        badgePrivacy.setLevelThresholds(levelThresholds);
        badgePrivacy.setBadgeLevelImageURIs(privacyImageUris);
        badgePrivacy.setBadgeLevelNames(privacyNames);
        badgePrivacy.setBadgeLevelDescriptions(privacyDescriptions);


        // Deploy ZK Privacy Badge
        PassportDevZKBadge passportTestBadge = new PassportDevZKBadge(resolver, easAddress);
        passportTestBadge.toggleAttester(gitcoinAttester, true);
        passportTestBadge.setEASAddress(easAddress);
        passportTestBadge.setLevelThresholds(levelThresholds);
        passportTestBadge.setBadgeLevelImageURIs(privacyImageUris);
        passportTestBadge.setBadgeLevelNames(privacyNames);
        passportTestBadge.setBadgeLevelDescriptions(privacyDescriptions);

        vm.stopBroadcast();

        console.log("PassportDevZKBadge (ZK Rollups) deployed at:", address(badgeRollups));
        console.log("PassportDevZKBadge (ZK Infra) deployed at:", address(badgeInfra));
        console.log("PassportDevZKBadge (ZK Privacy) deployed at:", address(badgePrivacy));
        console.log("PassportDevZKBadge (Test) deployed at:", address(passportTestBadge));
    }
}
