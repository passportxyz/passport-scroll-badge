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

        // Set level thresholds (example values, adjust as needed)
        uint256[] memory levelThresholds = new uint256[](3);
        levelThresholds[0] = 100;
        levelThresholds[1] = 200;
        levelThresholds[2] = 300;

        // Set badge level image URIs (example values, replace with actual URIs)
        string[] memory imageURIs = new string[](4);
        imageURIs[0] = "https://example.com/no-score.png";
        imageURIs[1] = "https://example.com/level1.png";
        imageURIs[2] = "https://example.com/level2.png";
        imageURIs[3] = "https://example.com/level3.png";

        // Set badge level names
        string[] memory names = new string[](4);
        names[0] = "No Score";
        names[1] = "ZK Rollup Talent";
        names[2] = "ZK Game Talent";
        names[3] = "ZK Privacy Talent";

        // Set badge level descriptions
        string[] memory descriptions = new string[](4);
        descriptions[0] = "No contributions yet";
        descriptions[1] =
            "Contributors to zkrollups including Aztec, zksync, taiko, Scroll, Polygon zkEVM, Linea, Manta Pacific, Starknet";
        descriptions[2] = "Contributors to zk games including 0xParc, Cartridge, etc";
        descriptions[3] = "Contributors to privacy focused L1s including ZCash, Aleo, Mina, etc";

        PassportDevZKBadge badge = new PassportDevZKBadge(resolver, easAddress);

        badge.toggleAttester(gitcoinAttester, true);
        badge.setEASAddress(easAddress);
        badge.setLevelThresholds(levelThresholds);
        badge.setBadgeLevelImageURIs(imageURIs);
        badge.setBadgeLevelNames(names);
        badge.setBadgeLevelDescriptions(descriptions);

        vm.stopBroadcast();

        console.log("PassportDevZKBadge deployed at:", address(badge));
    }
}
