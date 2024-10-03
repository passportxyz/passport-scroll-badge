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
import {ScrollBadgeCustomPayload} from "@canvas/badge/extensions/ScrollBadgeCustomPayload.sol";
import {Unauthorized, CannotUpgrade} from "@canvas/Errors.sol";
import {ScrollBadge} from "@canvas/badge/ScrollBadge.sol";
import "forge-std/console.sol";

string constant PASSPORT_DEV_ZK_SCROLL_BADGE_SCHEMA = "uint256 firstTxTimestamp";

/// @title PassportDevZKBadge
/// @notice A badge that represents the user's passport score level.
contract PassportDevZKBadge is ScrollBadge, ScrollBadgeAccessControl, ScrollBadgeCustomPayload, ScrollBadgeSingleton, IScrollBadgeUpgradeable {
    /// @dev Emitted when a badge is upgraded
    /// @param oldLevel The old badge level
    /// @param newLevel The new badge level
    event Upgrade(uint256 oldLevel, uint256 newLevel);

    /// @dev levelThresholds[0] is the threshold for level 1
    uint256[] public levelThresholds;

    /// @dev badgeLevelImageURIs[0] is the URI for no score, badgeLevelImageURIs[1] is the URI for level 1, etc.
    /// @dev Therefore this array should have a length of levelThresholds.length + 1
    string[] public badgeLevelImageURIs;

    /// @dev badgeLevelNames[0] is the name for no score, badgeLevelNames[1] is the name for level 1, etc.
    /// @dev Therefore this array should have a length of levelThresholds.length + 1
    string[] public badgeLevelNames;

    /// @dev badgeLevelDescriptions[0] is the description for no score, badgeLevelDescriptions[1] is the description for level 1, etc.
    /// @dev Therefore this array should have a length of levelThresholds.length + 1
    string[] public badgeLevelDescriptions;

    /// @dev badge UID => current level
    mapping(bytes32 => uint256) public badgeLevel;

    constructor(address resolver_) ScrollBadge(resolver_) Ownable() {}

    function decodePayloadData(bytes memory data) public pure returns (uint256) {
        return abi.decode(data, (uint256));
    }

    /// @inheritdoc ScrollBadge
    function onIssueBadge(Attestation calldata attestation)
        internal
        override(ScrollBadge, ScrollBadgeAccessControl, ScrollBadgeSingleton, ScrollBadgeCustomPayload)
        returns (bool)
    {
        bytes memory payload = getPayload(attestation);
        (uint256 level) = decodePayloadData(payload);


        if (level == 0) {
            revert Unauthorized();
        }

        badgeLevel[attestation.uid] = level;

        return super.onIssueBadge(attestation);
    }

    /// @inheritdoc ScrollBadge
    function onRevokeBadge(Attestation calldata attestation)
        internal
        override(ScrollBadge, ScrollBadgeAccessControl, ScrollBadgeSingleton, ScrollBadgeCustomPayload)
        returns (bool)
    {
        return super.onRevokeBadge(attestation);
    }

    /// @notice Check the level of the user's badge
    /// @param attestation The attestation to check
    /// @return The level of the user's badge
    function checkLevel(Attestation memory attestation) public view returns (uint256) {
        (uint256 level) = abi.decode(attestation.data, (uint256));
        
        return level;
    }

    /// @inheritdoc IScrollBadgeUpgradeable
    function canUpgrade(bytes32 uid) external view returns (bool) {
        Attestation memory badge = getAndValidateBadge(uid);

        uint256 newLevel = checkLevel(badge);

        uint256 oldLevel = badgeLevel[uid];

        return newLevel > oldLevel;
    }

    // / @inheritdoc IScrollBadgeUpgradeable
    // / @dev Only the badge recipient can upgrade their badge
    // / @dev The new level must be higher than the current level
    function upgrade(bytes32 uid) external {
        Attestation memory badge = getAndValidateBadge(uid);

        if (msg.sender != badge.recipient) {
            revert Unauthorized();
        }

        uint256 newLevel = checkLevel(badge);

        uint256 oldLevel = badgeLevel[uid];

        if (newLevel <= oldLevel) {
            revert CannotUpgrade(uid);
        }

        badgeLevel[uid] = newLevel;
        emit Upgrade(oldLevel, newLevel);
    }

    /// @inheritdoc ScrollBadge
    function badgeTokenURI(bytes32 uid) public view override returns (string memory) {
        uint256 level = badgeLevel[uid];
        console.log("level", level);
        string memory name = badgeLevelNames[level];
        console.log("name", name);
        string memory description = badgeLevelDescriptions[level];
        console.log("description", description);
        string memory image = badgeLevelImageURIs[level];
        console.log("image", image);
        string memory tokenUriJson = Base64.encode(
            abi.encodePacked('{"name":"', name, '", "description":"', description, '", "image": "', image, '"}')
        );

        return string(abi.encodePacked("data:application/json;base64,", tokenUriJson));
    }

    // Admin functions

    /// @notice Set the level thresholds
    /// @param levelsThresholds_ The new level thresholds
    /// @dev levelThresholds[0] is the threshold for level 1
    function setLevelThresholds(uint256[] memory levelsThresholds_) external onlyOwner {
        levelThresholds = levelsThresholds_;
    }

    /// @notice Set the badge level image URIs
    /// @param badgeLevelImageURIs_ The new badge level image URIs
    /// @dev The length of this array should be levelThresholds.length + 1
    function setBadgeLevelImageURIs(string[] memory badgeLevelImageURIs_) external onlyOwner {
        badgeLevelImageURIs = badgeLevelImageURIs_;
    }

    /// @notice Set the badge level names
    /// @param badgeLevelNames_ The new badge level names
    /// @dev The length of this array should be levelThresholds.length + 1
    function setBadgeLevelNames(string[] memory badgeLevelNames_) external onlyOwner {
        badgeLevelNames = badgeLevelNames_;
    }

    /// @notice Set the badge level descriptions
    /// @param badgeLevelDescriptions_ The new badge level descriptions
    /// @dev The length of this array should be levelThresholds.length + 1
    function setBadgeLevelDescriptions(string[] memory badgeLevelDescriptions_) external onlyOwner {
        badgeLevelDescriptions = badgeLevelDescriptions_;
    }

    /// @inheritdoc ScrollBadgeCustomPayload
    function getSchema() public pure override returns (string memory) {
        return PASSPORT_DEV_ZK_SCROLL_BADGE_SCHEMA;
    }
}
