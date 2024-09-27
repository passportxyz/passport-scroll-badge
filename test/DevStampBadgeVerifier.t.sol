// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/test.sol";
import {SigUtils} from "./utils/SigUtils.sol";
import "src/DevStampBadgeVerifier.sol";
// import {MockERC20} from "./utils/MockERC20.sol";



contract DevStampBadgeVerifierTest is Test {
    DevStampBadgeVerifier internal verifier;
    SigUtils internal sigUtils;

    uint256 internal ownerPrivateKey;
    uint256 internal spenderPrivateKey;

    address internal owner;
    address internal spender;

    function setUp() public {
        verifier = new DevStampBadgeVerifier();
        sigUtils = new SigUtils(verifier.computeDomainSeparator());

        ownerPrivateKey = 0xA11CE;
        spenderPrivateKey = 0xB0B;

        owner = vm.addr(ownerPrivateKey);
        spender = vm.addr(spenderPrivateKey);

        // token.mint(owner, 1e18);
    }

    function testPermit() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: owner,
            spender: spender,
            value: 1e18,
            nonce: 0,
            deadline: 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        verifier.permit(
            permit.owner,
            permit.spender,
            permit.value,
            permit.deadline,
            v,
            r,
            s
        );

        // assertEq(token.allowance(owner, spender), 1e18);
        // assertEq(token.nonces(owner), 1);
    }
}

