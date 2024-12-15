// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IXAllocationVotingGovernor} from "./interfaces/IXAllocationVotingGovernor.sol";
import {IX2EarnRewardsPool} from "./interfaces/IX2EarnRewardsPool.sol";
import {IX2EarnApps} from "./interfaces/IX2EarnApps.sol";
import {IXAllocationPool} from "./interfaces/IXAllocationPool.sol";

/**
 * @title EndorsersRewardDistributor
 * @notice This contract is responsible for distributing rewards (from previous round) to endorsers.
 * The percentage of the reward is fixed, but can be set by the admin.
 * Rewards can be distributed only once per round.
 * Rewards amount is calculated based on the tier of their X-Node.
 * Rewards are distributed through the `X2EarnRewardsPool` contract.
 */
contract EndorsersRewardDistributor is
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    event EndorsersRewardsDistributed(
        uint256 roundId,
        uint256 totalEndorsersRewards,
        address[] endorsers
    );

    error UnauthorizedUser(address user);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // ---------- Storage ------------ //

    struct EndorsersRewardDistributorStorage {
        // constants
        bytes32 appId;
        uint256 startRound;
        // contracts
        IXAllocationVotingGovernor allocationVotingGovernor;
        IX2EarnRewardsPool rewardsPool;
        IX2EarnApps x2earnApps;
        IXAllocationPool allocationPool;
        // state
        mapping(uint256 roundId => bool) rewardsDistributed;
        uint256 rewardsPercentage;
    }

    // keccak256(abi.encode(uint256(keccak256("storage.EndorsersRewardDistributor")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant EndorsersRewardDistributorStorageLocation =
        0xc9931bd7ecbba177fc71b0ded00eb01d4035361d4a0ee711add00987aca69000;

    function _getEndorsersRewardDistributorStorage()
        private
        pure
        returns (EndorsersRewardDistributorStorage storage $)
    {
        assembly {
            $.slot := EndorsersRewardDistributorStorageLocation
        }
    }

    struct InitParams {
        address upgrader;
        address admin;
        bytes32 appId;
        address allocationVotingGovernor;
        address rewardsPool;
        address x2earnApps;
        address allocationPool;
        uint256 startRound;
        uint256 rewardsPercentage;
    }

    /// @notice Initializes the contract
    function initialize(
        InitParams memory _params
    ) external initializer {
        require(
            _params.upgrader != address(0),
            "EndorsersRewardDistributor: upgrader is the zero address"
        );
        require(
            _params.admin != address(0),
            "EndorsersRewardDistributor: admin is the zero address"
        );
        require(
            _params.appId != bytes32(0),
            "EndorsersRewardDistributor: appId is the zero address"
        );
        require(
            _params.allocationVotingGovernor != address(0),
            "EndorsersRewardDistributor: allocationVotingGovernor is the zero address"
        );
        require(
            _params.rewardsPool != address(0),
            "EndorsersRewardDistributor: rewardsPool is the zero address"
        );
        require(
            _params.startRound > 0,
            "EndorsersRewardDistributor: startRound is the zero address"
        );
        require(
            _params.x2earnApps != address(0),
            "EndorsersRewardDistributor: x2earnApps is the zero address"
        );
        require(
            _params.allocationPool != address(0),
            "EndorsersRewardDistributor: allocationPool is the zero address"
        );
        require(
            _params.rewardsPercentage > 0 &&
                _params.rewardsPercentage <= 100,
            "EndorsersRewardDistributor: rewardsPercentage must be between 0 and 100"
        );

        // Initialize modules
        __UUPSUpgradeable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();

        // Set roles
        _grantRole(DEFAULT_ADMIN_ROLE, _params.admin);
        _grantRole(UPGRADER_ROLE, _params.upgrader);

        // Get the storage
        EndorsersRewardDistributorStorage
            storage $ = _getEndorsersRewardDistributorStorage();

        // Set constants
        $.appId = _params.appId;
        $.startRound = _params.startRound;

        // Set contracts
        $.allocationVotingGovernor = IXAllocationVotingGovernor(
            _params.allocationVotingGovernor
        );
        $.rewardsPool = IX2EarnRewardsPool(_params.rewardsPool);
        $.x2earnApps = IX2EarnApps(_params.x2earnApps);
        $.allocationPool = IXAllocationPool(_params.allocationPool);

        // Set params
        $.rewardsPercentage = _params.rewardsPercentage;
    }

    // ---------- Modifiers ------------ //

    /**
     * @dev Modifier to restrict access to only the admin role and the app admin role.
     * @param appId the app ID
     */
    /// @notice Modifier to check if the user has the required role or is the DEFAULT_ADMIN_ROLE
    /// @param role - the role to check
    modifier onlyRoleOrAdmin(bytes32 role) {
        if (
            !hasRole(role, msg.sender) &&
            !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)
        ) {
            revert UnauthorizedUser(msg.sender);
        }
        _;
    }

    // ---------- Authorizers ---------- //

    /// @notice Authorizes the upgrade of the contract
    /// @param newImplementation - the new implementation address
    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyRole(UPGRADER_ROLE) {}

    // ---------- Setters ---------- //

    /// @notice Distributes rewards to endorsers for the previous round
    function distributeRewards() external nonReentrant {
        // Get the storage
        EndorsersRewardDistributorStorage
            storage $ = _getEndorsersRewardDistributorStorage();

        // get current round
        uint256 currentRound = $.allocationVotingGovernor.currentRoundId();
        // we always distribute the rewards for the previous round (so we are sure that the allocation is set)
        uint256 roundToDistribute = currentRound - 1;
        require(
            roundToDistribute > $.startRound,
            "EndorsersRewardDistributor: current round is less than start round"
        );

        // check that rewards for this round are not already distributed
        require(
            !$.rewardsDistributed[roundToDistribute],
            "EndorsersRewardDistributor: rewards for this round are already distributed"
        );

        $.rewardsDistributed[roundToDistribute] = true;

        // get the amount of rewards the app earned for this round
        (uint256 appRewards, , , ) = $.allocationPool.roundEarnings(
            roundToDistribute,
            $.appId
        );
        uint256 totalEndorsersRewards = (appRewards * $.rewardsPercentage) /
            100;

        // Retrieve the endorsers
        address[] memory endorsers = $.x2earnApps.getEndorsers($.appId);

        // For each endorser get its score and sum all scores to get the total score
        uint256 totalEndorsersScore = 0;
        uint256[] memory endorsersScores = new uint256[](endorsers.length);
        for (uint256 i = 0; i < endorsers.length; i++) {
            uint256 score = $.x2earnApps.getUsersEndorsementScore(endorsers[i]);

            totalEndorsersScore += score;
            endorsersScores[i] = score;
        }

        // For each endorser, calculate its rewards
        for (uint256 i = 0; i < endorsers.length; i++) {
            uint256 endorserRewards = (totalEndorsersRewards *
                endorsersScores[i]) / totalEndorsersScore;

            string memory proof = buildProof(roundToDistribute);

            $.rewardsPool.distributeRewardDeprecated(
                $.appId,
                endorserRewards,
                endorsers[i],
                proof
            );
        }

        emit EndorsersRewardsDistributed(
            roundToDistribute,
            totalEndorsersRewards,
            endorsers
        );
    }

    /// @notice Sets the rewards percentage
    /// @param _rewardsPercentage - the new rewards percentage
    function setRewardsPercentage(
        uint256 _rewardsPercentage
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        EndorsersRewardDistributorStorage
            storage $ = _getEndorsersRewardDistributorStorage();

        $.rewardsPercentage = _rewardsPercentage;
    }

    // ---------- Getters ---------- //

    /// @notice Returns whether rewards have been distributed for a given round
    /// @param roundId - the round ID
    /// @return whether rewards have been distributed for the given round
    function rewardsDistributed(uint256 roundId) external view returns (bool) {
        EndorsersRewardDistributorStorage
            storage $ = _getEndorsersRewardDistributorStorage();

        require(
            roundId > $.startRound,
            "EndorsersRewardDistributor: roundId is less than start round"
        );

        return $.rewardsDistributed[roundId];
    }

    /// @notice Returns the addresses of the contracts used by the contract
    function getContractsAddresses()
        external
        view
        returns (address, address, address, address)
    {
        EndorsersRewardDistributorStorage
            storage $ = _getEndorsersRewardDistributorStorage();

        return (
            address($.allocationVotingGovernor),
            address($.rewardsPool),
            address($.x2earnApps),
            address($.allocationPool)
        );
    }

    /// @notice Returns the rewards percentage
    function getRewardsPercentage() external view returns (uint256) {
        EndorsersRewardDistributorStorage
            storage $ = _getEndorsersRewardDistributorStorage();

        return $.rewardsPercentage;
    }

    /// @notice Returns the start round
    function getStartRound() external view returns (uint256) {
        EndorsersRewardDistributorStorage
            storage $ = _getEndorsersRewardDistributorStorage();

        return $.startRound;
    }

    /// @notice Returns the version of the contract
    function version() external pure returns (string memory) {
        return "1";
    }

    // ---------- Internal ---------- //

    /**
     * @dev Builds a proof for the rewards distribution
     * @param roundId - the round ID
     * @return the proof
     */
    function buildProof(uint256 roundId) internal pure returns (string memory) {
        // Initialize an empty JSON bytes array with version
        bytes memory json = abi.encodePacked('{"version": 2');

        // Add description
        json = abi.encodePacked(
            json,
            ',"description": "Endorsement rewards for round ',
            roundId,
            '"'
        );

        // Add empty proof and empty impact
        json = abi.encodePacked(json, ',"proof": "{}"');
        json = abi.encodePacked(json, ',"impact": "{}"');

        // Close the JSON object
        json = abi.encodePacked(json, "}");

        return string(json);
    }
}
