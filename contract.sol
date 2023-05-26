// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract StackUp {
    // added the REJECTED, APPROVED, and REWARDED status
    enum playerQuestStatus {
        NOT_JOINED,
        JOINED,
        SUBMITTED,
        REJECTED,
        APPROVED,
        REWARDED
    }

    // contains the mapping of questId => Quest
    struct Campaign {
        uint256 campaignId;
        uint8 nextQuestId;
        uint8 numberOfQuests;
        uint8 rewardPool;
        string title;
        mapping(uint256 => Quest) quests;
    }

    // added the startTime and endTime (in unix timestamp)
    struct Quest {
        uint256 questId;
        uint256 numberOfPlayers;
        string title;
        uint8 reward;
        uint256 numberOfRewards;
        uint256 startTime;
        uint256 endTime;
    }

    address public admin;
    uint256 public nextCampaignId;
    mapping(uint256 => Campaign) public campaigns;

    // changed the mapping to include the campaignId
    // userAddress => campaignId => questId => playerQuestStatus
    mapping(address => mapping(uint256 => mapping(uint256 => playerQuestStatus)))
        public playerQuestStatuses;

    constructor() {
        admin = msg.sender;
    }

    function createCampaign(
        uint8 rewardPool_,
        uint8 numberOfQuests_,
        string calldata title_
    ) external onlyAdmin {
        campaigns[nextCampaignId].campaignId = nextCampaignId;
        campaigns[nextCampaignId].rewardPool = rewardPool_;
        campaigns[nextCampaignId].numberOfQuests = numberOfQuests_;
        campaigns[nextCampaignId].title = title_;
    }

    function createQuest(
        uint256 campaignId,
        string calldata title_,
        uint8 reward_,
        uint256 numberOfRewards_,
        uint256 startTime_,
        uint256 endTime_
    ) external onlyAdmin {
        Campaign storage campaign = campaigns[campaignId];
        require(
            campaign.nextQuestId < campaign.numberOfQuests,
            "Max Number of Quests Reached"
        );
        campaign.quests[campaign.nextQuestId].questId = campaign.nextQuestId;
        campaign.quests[campaign.nextQuestId].title = title_;
        campaign.quests[campaign.nextQuestId].reward = reward_;
        campaign
            .quests[campaign.nextQuestId]
            .numberOfRewards = numberOfRewards_;
        campaign.quests[campaign.nextQuestId].startTime = startTime_;
        campaign.quests[campaign.nextQuestId].endTime = endTime_;
        campaign.nextQuestId++;
    }

    function joinQuest(uint256 campaignId, uint256 questId)
        external
        questExists(campaignId, questId)
        questRunning(campaignId, questId)
    {
        require(
            playerQuestStatuses[msg.sender][campaignId][questId] ==
                playerQuestStatus.NOT_JOINED,
            "Player has already joined/submitted this quest"
        );
        playerQuestStatuses[msg.sender][campaignId][questId] = playerQuestStatus
            .JOINED;

        Quest storage thisQuest = campaigns[campaignId].quests[questId];
        thisQuest.numberOfPlayers++;
    }

    function submitQuest(uint256 campaignId, uint256 questId)
        external
        questExists(campaignId, questId)
        questRunning(campaignId, questId)
    {
        require(
            playerQuestStatuses[msg.sender][campaignId][questId] ==
                playerQuestStatus.JOINED,
            "Player must first join the quest"
        );
        playerQuestStatuses[msg.sender][campaignId][questId] = playerQuestStatus
            .SUBMITTED;
    }

    function rejectQuest(uint256 campaignId, uint256 questId, address user)
        external
        questExists(campaignId, questId)
        questEnded(campaignId, questId)
        onlyAdmin
    {
        require(
            playerQuestStatuses[msg.sender][campaignId][questId] ==
                playerQuestStatus.SUBMITTED,
            "Player must submit the quest"
        );

        playerQuestStatuses[user][campaignId][questId] = playerQuestStatus
            .REJECTED;
    }

    function approveQuest(uint256 campaignId, uint256 questId, address user)
        external
        questExists(campaignId, questId)
        questEnded(campaignId, questId)
        onlyAdmin
    {
        require(
            playerQuestStatuses[user][campaignId][questId] ==
                playerQuestStatus.APPROVED,
            "Player must submit the quest"
        );

        playerQuestStatuses[msg.sender][campaignId][questId] = playerQuestStatus
            .APPROVED;
    }

    // this function needs to be payable so the admin can transfer the reward
    function rewardQuest(uint256 campaignId, uint256 questId, address user)
        external
        payable
        questExists(campaignId, questId)
        questEnded(campaignId, questId)
        onlyAdmin
    {
        require(
            playerQuestStatuses[user][campaignId][questId] ==
                playerQuestStatus.REWARDED,
            "Player must submit the quest"
        );

        playerQuestStatuses[msg.sender][campaignId][questId] = playerQuestStatus
            .REJECTED;

        // transfer the reward, for now the value is the same as the reward since I don't know how to convert to eth
        require(msg.value > campaigns[campaignId].quests[questId].reward, "Reward must be greater than than the quest reward");
        (bool sent, bytes memory data) = user.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }

    function deleteQuest(uint256 campaignId, uint256 questId)
        external
        questExists(campaignId, questId)
        onlyAdmin
    {
        delete campaigns[campaignId].quests[questId];
    }

    function deleteCampaign(uint256 campaignId)
        external
        campaignExists(campaignId)
        onlyAdmin
    {
        delete campaigns[campaignId];
    }

    function editQuest(
        uint256 campaignId,
        uint256 questId,
        string calldata title_,
        uint8 reward_,
        uint256 numberOfRewards_
    ) external questExists(campaignId, questId) onlyAdmin {
        Campaign storage campaign = campaigns[campaignId];
        campaign.quests[questId].title = title_;
        campaign.quests[questId].reward = reward_;
        campaign.quests[questId].numberOfRewards = numberOfRewards_;
    }

    function editCampaign(
        uint256 campaignId,
        uint8 numberOfQuests_,
        uint8 rewardPool_,
        string calldata title_
    ) external campaignExists(campaignId) onlyAdmin {
        Campaign storage campaign = campaigns[campaignId];
        campaign.numberOfQuests = numberOfQuests_;
        campaign.rewardPool = rewardPool_;
        campaign.title = title_;
    }

    modifier questExists(uint256 campaignId, uint256 questId) {
        Campaign storage campaign = campaigns[campaignId];
        require(campaign.quests[questId].reward != 0, "Quest does not exist");
        _;
    }

    modifier campaignExists(uint256 campaignId) {
        require(
            campaigns[campaignId].numberOfQuests != 0,
            "Campaign does not exist"
        );
        _;
    }

    modifier questRunning(uint256 campaignId, uint256 questId) {
        Campaign storage campaign = campaigns[campaignId];
        require(
            block.timestamp < campaign.quests[questId].endTime,
            "Quest has ended"
        );
        require(
            block.timestamp > campaign.quests[questId].startTime,
            "Quest isn't started yet"
        );
        _;
    }

    modifier questEnded(uint256 campaignId, uint256 questId) {
        Campaign storage campaign = campaigns[campaignId];
        require(
            block.timestamp > campaign.quests[questId].endTime,
            "Quest still running"
        );
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can create quests");
        _;
    }
}
