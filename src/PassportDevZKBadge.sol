// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Attestation, IEAS} from "@eas/contracts/EAS.sol";
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
import {SchemaResolver, ISchemaResolver} from "@eas/contracts/resolver/SchemaResolver.sol";

/// @dev The schema for the passport dev ZK Scroll badge
string constant PASSPORT_DEV_ZK_SCROLL_BADGE_SCHEMA = "uint256 updatedScore, bytes32[] providerHashes";

/// @title PassportDevZKBadge
/// @notice A badge contract representing the user's passport score level on the Scroll network
/// @dev This contract extends ScrollBadge with custom functionality for level-based badges
contract PassportDevZKBadge is
    ScrollBadge,
    ScrollBadgeAccessControl,
    ScrollBadgeCustomPayload,
    ScrollBadgeSingleton,
    SchemaResolver
{
    /// @notice The instance of the EAS contract
    IEAS public eas;

    /// @dev Emitted when a badge is upgraded
    /// @param oldLevel The old badge level
    /// @param newLevel The new badge level
    event Upgrade(uint256 oldLevel, uint256 newLevel);

    /// @dev Emitted when the EAS contract address is set
    event EASSet(address easAddress);

    /// @dev Thrown when a zero value is passed where it's not allowed
    error ZeroValue();

    /// @dev Thrown when attempting to use a hash that has already been used
    error HashUsed();

    /// @notice The schema to upgrade a badge
    bytes32 public upgradeSchema;

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

    /// @notice Mapping of badge level to user address
    /// @dev badge UID => current level
    mapping(address => uint256) public badgeLevel;

    /// @notice Mapping of used hashes, to prevent reusing the same passport hash
    /// @dev usedPassportHashes[passportHash] => true
    mapping(bytes32 => bool) public usedPassportHashes;

    mapping(address => bytes32[]) public userProviderHashes;

    /// @notice Initializes the PassportDevZKBadge contract
    /// @param resolver_ The address of the resolver contract
    constructor(address resolver_, address eas_) ScrollBadge(resolver_) SchemaResolver(IEAS(eas_)) Ownable() {
        upgradeSchema = _eas.getSchemaRegistry().register(
            "uint256 updatedScore, bytes32[] providerHashes",
            ISchemaResolver(address(this)), // resolver
            true // revocable
        );
    }

    /// @notice Decodes the payload data to extract the badge level
    /// @param data The encoded payload data
    /// @return The decoded badge level as a uint256
    /// @notice Decodes the payload data to extract the badge level and provider hashes
    /// @param data The encoded payload data
    /// @return The decoded badge level as a uint256 and an array of provider hashes
    function decodePayloadData(bytes memory data) public pure returns (uint256, bytes32[] memory) {
        return abi.decode(data, (uint256, bytes32[]));
    }

    /// @dev Checks and updates the provider hashes
    /// @param providerHashes Array of provider hashes to check and update
    function _checkAndUpdateProviderHashes(bytes32[] memory providerHashes) internal {
        for (uint256 i = 0; i < providerHashes.length; i++) {
            if (usedPassportHashes[providerHashes[i]]) {
                revert HashUsed();
            }
            usedPassportHashes[providerHashes[i]] = true;
        }
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
        (uint256 level, bytes32[] memory providerHashes) = decodePayloadData(payload);

        if (level == 0) {
            revert Unauthorized();
        }

        _checkAndUpdateProviderHashes(providerHashes);

        badgeLevel[attestation.recipient] = level;
        userProviderHashes[attestation.recipient] = providerHashes;

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
        if (!isAttester[attestation.attester]) {
            revert Unauthorized();
        }

        badgeLevel[attestation.recipient] = 0;

        for (uint256 i = 0; i < userProviderHashes[attestation.recipient].length; i++) {
            usedPassportHashes[userProviderHashes[attestation.recipient][i]] = false;
        }

        userProviderHashes[attestation.recipient] = new bytes32[](0);
        return super.onRevokeBadge(attestation);
    }

    /// @inheritdoc ScrollBadge
    /// @dev Generates the token URI for a given badge
    /// @param uid The unique identifier of the badge
    /// @return A string containing the token URI
    function badgeTokenURI(bytes32 uid) public view override returns (string memory) {
        address recipient = getAttestation(uid).recipient;
        uint256 level = badgeLevel[recipient];
        string memory name = badgeLevelNames[level];
        string memory description = badgeLevelDescriptions[level];
        string memory image = badgeLevelImageURIs[level];

        // Encode the JSON metadata
        string memory tokenUriJson = Base64.encode(
            abi.encodePacked('{"name":"', name, '", "description":"', description, '", "image": "', image, '"}')
        );

        return string(abi.encodePacked("data:application/json;base64,", tokenUriJson));
    }

    /// @notice Return an attestation for a given UID
    /// @param attestationUID The UID of the attestation
    /// @return The Attestation struct for the given UID
    function getAttestation(bytes32 attestationUID) public view returns (Attestation memory) {
        Attestation memory attestation = eas.getAttestation(attestationUID);
        return attestation;
    }

    // SchemaResolver overrides
    /// @inheritdoc SchemaResolver
    /// @dev Handles the attestation process for upgrading a badge
    /// @param attestation The attestation data
    /// @param value The value sent with the attestation (unused in this implementation)
    /// @return A boolean indicating whether the attestation was successful
    function onAttest(Attestation calldata attestation, uint256 value)
        internal
        virtual
        override(SchemaResolver)
        returns (bool)
    {
        if (!isAttester[attestation.attester]) {
            revert Unauthorized();
        }

        bytes memory payload = getPayload(attestation);
        (uint256 newLevel, bytes32[] memory providerHashes) = decodePayloadData(payload);
        _checkAndUpdateProviderHashes(providerHashes);

        address recipient = attestation.recipient;

        uint256 oldLevel = badgeLevel[recipient];

        if (newLevel <= oldLevel) {
            revert CannotUpgrade(attestation.uid);
        }

        badgeLevel[recipient] = newLevel;
        userProviderHashes[recipient] = providerHashes;
        emit Upgrade(oldLevel, newLevel);
        return true;
    }

    /// @inheritdoc SchemaResolver
    /// @dev Handles the revocation process for a badge
    /// @param attestation The attestation data
    /// @param value The value sent with the revocation (unused in this implementation)
    /// @return A boolean indicating whether the revocation was successful
    function onRevoke(Attestation calldata attestation, uint256 value)
        internal
        virtual
        override(SchemaResolver)
        returns (bool)
    {
        if (!isAttester[attestation.attester]) {
            revert Unauthorized();
        }

        badgeLevel[attestation.recipient] = 0;

        for (uint256 i = 0; i < userProviderHashes[attestation.recipient].length; i++) {
            usedPassportHashes[userProviderHashes[attestation.recipient][i]] = false;
        }

        userProviderHashes[attestation.recipient] = new bytes32[](0);
        return true;
    }

    // Admin functions

    /**
     * @dev Sets the address of the EAS contract.
     * @param _easContractAddress The address of the EAS contract.
     */
    function setEASAddress(address _easContractAddress) external onlyOwner {
        if (_easContractAddress == address(0)) {
            revert ZeroValue();
        }
        eas = IEAS(_easContractAddress);
        emit EASSet(_easContractAddress);
    }

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
