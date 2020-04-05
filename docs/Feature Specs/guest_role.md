- Roles
  + Admin
    * Can Add other users to this group
  + Member
    * Can belong to group, as well as other groups
  + Guest
    * Two options of how many groups they can belong to
      - Only One Group or Multiple Groups
    * Does not recieve anything shared with "All Domain Members" (previously everyone)
    * Does not show up in the list of users a domain member can share with
  + Anonymous 

### Guest Scenarios

As a member
If I invite a guest
And I do not connect to any Hives
And I do not connect to any Groups
Then when the guest joins
The Guest should not see any Hives
And the guest should not see any groups
And the guest should only see me as a user

As a member
If I invite a guest
And I do not connect to a Hive
And I do not connect to any Groups
Then when the guest joins
The Guest should see only the hives he is connected to
And the guest should not see any groups
And the guest should only see me as a user

As a member
If I invite a guest
And I do not connect to any Hives
And I do not connect to a Group
Then when the guest joins
The Guest should not see any Hives
And the guest should see only the groups he is connected to
And the guest should only see me as a user

As a member
If I invite a guest
And I do not connect to a Hive
And I do not connect to a Group
Then when the guest joins
The Guest should see the hives he is connected to
And the guest should see the groups he is connected to
And the guest should 
