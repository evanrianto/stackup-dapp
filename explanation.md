# Stackup Contract Explanation

## Features
- Quest review functionality - allow the admin to reject, approve or reward submissions
- Edit and delete quests - add functions to allow the admin to edit and delete quests
- Campaigns - introduce Campaigns, a new data structure and edit the smart contract to accommodate for this change
- Quest start and end time - add the quest start and end times for each quest struct as well as its corresponding effects e.g. users cannot join a quest that has ended

## Explanation
- Quest Review
> This feature adds new status for the quest. REJECTED, APPROVED, and REWARDED status was added for the admin to decide howt the quest status should be. This function needs to be called only when the quest is SUMBITTED, hence the require SUBMITTED status. All three status get their own function to call by onlyAdmin(new modifier); rejectQuest, approveQuest, and rewardQuests needs campaignId, questId, and user address as the parameters. Only the reward function needs to be payable since the rewards needs to be transfered by the admin.
    
- Edit and Delete Quests
> This feature is a simple update to edit and delete the quests. Accessing from the campaign new data structure.
    
- Campaigns
> This feature almost changed everything in every aspect. This feature adds a new data structure that now holds the quests for the users and admins to interract. When creating a new quest, the contract check the max number of quests and the current number of quests. If its the same number, the process would be reverted with "Max Number of Quests Reached". When updating or deleting the quest, it needs to access the according campaign with campaignId.
    
- Quest Start and End Time
> This feature is a simple update to restrict the user when entering and submitting a quest
    
