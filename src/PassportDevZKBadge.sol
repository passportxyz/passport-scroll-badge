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
/// @notice A badge contract representing the user's passport score level on the Scroll network
/// @dev This contract extends ScrollBadge with custom functionality for level-based badges
contract PassportDevZKBadge is
    ScrollBadge,
    ScrollBadgeAccessControl,
    ScrollBadgeCustomPayload,
    ScrollBadgeSingleton,
    IScrollBadgeUpgradeable
{
    /// @dev Emitted when a badge is upgraded
    /// @param oldLevel The old badge level
    /// @param newLevel The new badge level
    event Upgrade(uint256 oldLevel, uint256 newLevel);

    /// @notice Array of level thresholds for badge levels
    /// @dev levelThresholds[0] is the threshold for level 1
    uint256[] public levelThresholds;

    /// @notice Array of image URIs for each badge level
    /// @dev badgeLevelImageURIs[0] is the URI for no score, badgeLevelImageURIs[1] is the URI for level 1, etc.
    /// @dev This array should have a length of levelThresholds.length + 1
    string[] public badgeLevelImageURIs;

    /// @notice Array of names for each badge level
    /// @dev badgeLevelNames[0] is the name for no score, badgeLevelNames[1] is the name for level 1, etc.
    /// @dev This array should have a length of levelThresholds.length + 1
    string[] public badgeLevelNames;

    /// @notice Array of descriptions for each badge level
    /// @dev badgeLevelDescriptions[0] is the description for no score, badgeLevelDescriptions[1] is the description for level 1, etc.
    /// @dev This array should have a length of levelThresholds.length + 1
    string[] public badgeLevelDescriptions;

    /// @notice Mapping of badge UID to current level
    /// @dev badge UID => current level
    mapping(bytes32 => uint256) public badgeLevel;

    /// @notice Initializes the PassportDevZKBadge contract
    /// @param resolver_ The address of the resolver contract
    constructor(address resolver_) ScrollBadge(resolver_) Ownable() {}

    /// @notice Decodes the payload data to extract the badge level
    /// @param data The encoded payload data
    /// @return The decoded badge level as a uint256
    function decodePayloadData(bytes memory data) public pure returns (uint256) {
        return abi.decode(data, (uint256));
    }

    /// @inheritdoc ScrollBadge
    /// @dev Handles the issuance of a new badge
    /// @param attestation The attestation data for the badge being issued
    /// @return A boolean indicating whether the badge issuance was successful
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
    /// @dev Handles the revocation of a badge
    /// @param attestation The attestation data for the badge being revoked
    /// @return A boolean indicating whether the badge revocation was successful
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
    /// @dev Checks if a badge can be upgraded
    /// @param uid The unique identifier of the badge
    /// @return A boolean indicating whether the badge can be upgraded
    function canUpgrade(bytes32 uid) external view returns (bool) {
        Attestation memory badge = getAndValidateBadge(uid);
        uint256 newLevel = checkLevel(badge);
        uint256 oldLevel = badgeLevel[uid];
        return newLevel > oldLevel;
    }

    /// @inheritdoc IScrollBadgeUpgradeable
    /// @dev Upgrades a badge to a new level
    /// @param uid The unique identifier of the badge to upgrade
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
    /// @dev Generates the token URI for a given badge
    /// @param uid The unique identifier of the badge
    /// @return A string containing the token URI
    function badgeTokenURI(bytes32 uid) public view override returns (string memory) {
        uint256 level = badgeLevel[uid];
        string memory name = badgeLevelNames[level];
        string memory description = badgeLevelDescriptions[level];
        string memory image = badgeLevelImageURIs[level];

        // Encode the JSON metadata
        string memory tokenUriJson = Base64.encode(
            abi.encodePacked('{"name":"', name, '", "description":"', description, '", "image": "', image, '"}')
        );

        return string(abi.encodePacked("data:application/json;base64,", tokenUriJson));
    }

    // Admin functions

    /// @notice Set the level thresholds for badge levels
    /// @dev Only the contract owner can call this function
    /// @param levelsThresholds_ The new level thresholds array
    /// @dev levelThresholds[0] is the threshold for level 1
    function setLevelThresholds(uint256[] memory levelsThresholds_) external onlyOwner {
        levelThresholds = levelsThresholds_;
    }

    /// @notice Set the badge level image URIs
    /// @dev Only the contract owner can call this function
    /// @param badgeLevelImageURIs_ The new badge level image URIs array
    /// @dev The length of this array should be levelThresholds.length + 1
    function setBadgeLevelImageURIs(string[] memory badgeLevelImageURIs_) external onlyOwner {
        badgeLevelImageURIs = badgeLevelImageURIs_;
    }

    /// @notice Set the badge level names
    /// @dev Only the contract owner can call this function
    /// @param badgeLevelNames_ The new badge level names array
    /// @dev The length of this array should be levelThresholds.length + 1
    function setBadgeLevelNames(string[] memory badgeLevelNames_) external onlyOwner {
        badgeLevelNames = badgeLevelNames_;
    }

    /// @notice Set the badge level descriptions
    /// @dev Only the contract owner can call this function
    /// @param badgeLevelDescriptions_ The new badge level descriptions array
    /// @dev The length of this array should be levelThresholds.length + 1
    function setBadgeLevelDescriptions(string[] memory badgeLevelDescriptions_) external onlyOwner {
        badgeLevelDescriptions = badgeLevelDescriptions_;
    }

    /// @inheritdoc ScrollBadgeCustomPayload
    /// @dev Returns the schema for the custom payload
    /// @return A string representing the schema for the passport dev ZK Scroll badge
    function getSchema() public pure override returns (string memory) {
        return PASSPORT_DEV_ZK_SCROLL_BADGE_SCHEMA;
    }
}
