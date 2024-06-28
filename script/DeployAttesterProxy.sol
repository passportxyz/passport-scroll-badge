// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/AttesterProxy.sol";
import {IEAS} from "@eas/contracts/IEAS.sol";

contract DeployAttesterProxy is Script {
    address constant issuer = 0x804233b96cbd6d81efeb6517347177ef7bD488ED;
    address constant eas = 0xC47300428b6AD2c7D03BB76D05A176058b47E6B0;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        IEAS easInstance = IEAS(eas);

        AttesterProxy attesterProxy = new AttesterProxy(easInstance);

        attesterProxy.toggleAttester(issuer, true);

        vm.stopBroadcast();
    }
}
