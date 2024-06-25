// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Attestation} from "@eas/contracts/EAS.sol";
import {IGitcoinPassportDecoder} from "./IGitcoinPassportDecoder.sol";

import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {ScrollBadgeSelfAttest} from "@canvas/badge/extensions/ScrollBadgeSelfAttest.sol";
import {ScrollBadgeSingleton} from "@canvas/badge/extensions/ScrollBadgeSingleton.sol";
import {Unauthorized} from "@canvas/Errors.sol";
import {ScrollBadge} from "@canvas/badge/ScrollBadge.sol";

/// @title PassportScoreScrollBadge
/// @notice A badge that represents the user's passport score level.
contract PassportScoreScrollBadge is
    ScrollBadge,
    ScrollBadgeSelfAttest,
    ScrollBadgeSingleton
{
    error CannotUpgrade();

    event Upgrade(uint256 oldLevel, uint256 newLevel);

    IGitcoinPassportDecoder public gitcoinPassportDecoder;

    // @dev levelThresholds[0] is the threshold for level 1
    uint256[] public levelThresholds;

    // @dev badgeLevelImageURIs[0] is the URI for no score, badgeLevelImageURIs[1] is the URI for level 1, etc.
    // @dev Therefore this array should have a length of levelThresholds.length + 1
    string[] public badgeLevelImageURIs;

    // badge UID => current level
    mapping(bytes32 => uint256) public badgeLevel;

    constructor(
        address resolver_,
        address gitcoinPassportDecoder_,
        uint256[] memory levelsThresholds_,
        string[] memory badgeLevelImageURIs_
    ) ScrollBadge(resolver_) {
        gitcoinPassportDecoder = IGitcoinPassportDecoder(
            gitcoinPassportDecoder_
        );
        levelThresholds = levelsThresholds_;
        badgeLevelImageURIs = badgeLevelImageURIs_;
    }

    /// @inheritdoc ScrollBadge
    function onIssueBadge(Attestation calldata attestation)
        internal
        override(ScrollBadge, ScrollBadgeSelfAttest, ScrollBadgeSingleton)
        returns (bool)
    {
        // @dev checkLevel will revert if there is no valid attestation
        uint256 level = checkLevel(attestation.recipient);

        if (level == 0) {
            revert Unauthorized();
        }

        badgeLevel[attestation.uid] = level;

        return super.onIssueBadge(attestation);
    }

    /// @inheritdoc ScrollBadge
    function onRevokeBadge(Attestation calldata attestation)
        internal
        override(ScrollBadge, ScrollBadgeSelfAttest, ScrollBadgeSingleton)
        returns (bool)
    {
        return super.onRevokeBadge(attestation);
    }

    /// @notice Check the level of the user's badge
    /// @param user The user address
    /// @return The level of the user's badge
    function checkLevel(address user) public view returns (uint256) {
        uint256 score = gitcoinPassportDecoder.getScore(user);
        uint256 level = 0;
        for (uint256 i = 0; i < levelThresholds.length; i++) {
            if (score >= levelThresholds[i]) {
                level = i + 1;
            }
        }
        return level;
    }

    /// @notice Upgrade the badge level of the recipient
    /// @param uid The badge UID
    /// @dev Only the badge recipient can upgrade their badge
    /// @dev The new level must be higher than the current level
    function upgrade(bytes32 uid) external {
        Attestation memory badge = getAndValidateBadge(uid);

        if (msg.sender != badge.recipient) {
            revert Unauthorized();
        }

        uint256 newLevel = checkLevel(badge.recipient);

        uint256 oldLevel = badgeLevel[uid];

        if (newLevel <= oldLevel) {
            revert CannotUpgrade();
        }

        badgeLevel[uid] = newLevel;
        emit Upgrade(oldLevel, newLevel);
    }

    /// @inheritdoc ScrollBadge
    function badgeTokenURI(bytes32 uid)
        public
        view
        override
        returns (string memory)
    {
        uint256 level = badgeLevel[uid];
        string memory name = string(
            abi.encode("Passport Score Level #", Strings.toString(level))
        );
        string memory description = "Passport Score Badge";
        string memory image = badgeLevelImageURIs[level];
        string memory tokenUriJson = Base64.encode(
            abi.encodePacked(
                '{"name":"',
                name,
                '", "description":"',
                description,
                ', "image": "',
                image,
                '"}'
            )
        );

        return
            string(
                abi.encodePacked("data:application/json;base64,", tokenUriJson)
            );
    }
}
