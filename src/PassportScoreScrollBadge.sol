// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Attestation} from "@eas/contracts/EAS.sol";
import {IGitcoinPassportDecoder} from "./IGitcoinPassportDecoder.sol";

import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {ScrollBadgeAccessControl} from "@canvas/badge/extensions/ScrollBadgeAccessControl.sol";
import {ScrollBadgeSingleton} from "@canvas/badge/extensions/ScrollBadgeSingleton.sol";
import {IScrollBadgeUpgradeable} from "@canvas/badge/extensions/IScrollBadgeUpgradeable.sol";
import {Unauthorized, CannotUpgrade} from "@canvas/Errors.sol";
import {ScrollBadge} from "@canvas/badge/ScrollBadge.sol";

/// @title PassportScoreScrollBadge
/// @notice A badge that represents the user's passport score level.
contract PassportScoreScrollBadge is
    ScrollBadge,
    ScrollBadgeAccessControl,
    ScrollBadgeSingleton,
    IScrollBadgeUpgradeable
{
    /// @dev Emitted when a badge is upgraded
    /// @param oldLevel The old badge level
    /// @param newLevel The new badge level
    event Upgrade(uint256 oldLevel, uint256 newLevel);

    IGitcoinPassportDecoder public gitcoinPassportDecoder;

    /// @dev levelThresholds[0] is the threshold for level 1
    uint256[] public levelThresholds;

    /// @dev badgeLevelImageURIs[0] is the URI for no score, badgeLevelImageURIs[1] is the URI for level 1, etc.
    /// @dev Therefore this array should have a length of levelThresholds.length + 1
    string[] public badgeLevelImageURIs;

    /// @dev badge UID => current level
    mapping(bytes32 => uint256) public badgeLevel;

    constructor(address resolver_, address gitcoinPassportDecoder_)
        ScrollBadge(resolver_) Ownable()
    {
        gitcoinPassportDecoder = IGitcoinPassportDecoder(
            gitcoinPassportDecoder_
        );
    }

    /// @inheritdoc ScrollBadge
    function onIssueBadge(Attestation calldata attestation)
        internal
        override(ScrollBadge, ScrollBadgeAccessControl, ScrollBadgeSingleton)
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
        override(ScrollBadge, ScrollBadgeAccessControl, ScrollBadgeSingleton)
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

    /// @inheritdoc IScrollBadgeUpgradeable
    function canUpgrade(bytes32 uid) external view returns (bool) {
        Attestation memory badge = getAndValidateBadge(uid);

        uint256 newLevel = checkLevel(badge.recipient);

        uint256 oldLevel = badgeLevel[uid];

        return newLevel > oldLevel;
    }

    /// @inheritdoc IScrollBadgeUpgradeable
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
            revert CannotUpgrade(uid);
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

    // Admin functions

    /// @notice Set the level thresholds
    /// @param levelsThresholds_ The new level thresholds
    /// @dev levelThresholds[0] is the threshold for level 1
    function setLevelThresholds(uint256[] memory levelsThresholds_)
        external
        onlyOwner
    {
        levelThresholds = levelsThresholds_;
    }

    /// @notice Set the badge level image URIs
    /// @param badgeLevelImageURIs_ The new badge level image URIs
    /// @dev The length of this array should be levelThresholds.length + 1
    function setBadgeLevelImageURIs(string[] memory badgeLevelImageURIs_)
        external
        onlyOwner
    {
        badgeLevelImageURIs = badgeLevelImageURIs_;
    }
}
