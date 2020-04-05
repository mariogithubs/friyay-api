<h4 style='color: red;'>DRAFT</h4>

**Updated: November 18, 2016**

**Work Estimate: 5**

#### PURPOSE
- To allow content to be shared with a group of people
- Only if something is shared to a group will it be seen by the group
    - The share tab will have a list of groups you can share with

#### QUESTIONS
- How can we indicate that a user is viewing content with the context of a Group only
- When sharing a Hive/SubHive with a Group, should we ask to also share all content within that Hive/SubHive?
  + Or, does it just share any content already shared with the Group + new content
  + Will there be a way to share a bunch of content at one time?

#### DESCRIPTION
##### BEHAVIOR
- A group is essentially a top level filter that scopes content based on what is shared with the group
- Users should be able create a group
- Users should be able to add other domain members to a group
- should we ask to share all subhives and tips with the people being shared with the Hive?

#### DEVELOPMENT THOUGHTS
##### Components
- **NEW** - Group Left Sidebar (to the left of the left menu)
  + Lists the Avatar of the group only
  + When an avatar is clicked
    * changes the left menu contents (hives and people)
    * Changes main view to show the TipFeed scoped to the group
  + Has an option at the top to open the Group Sidebar, revealing the names of each group
  + Has an + Add Group option, which will open the Popover form to create a new group
  + https://projects.invisionapp.com/d/main#/console/7265910/201538344/preview
- **NEW** - Group Sidebar Expanded
  + https://projects.invisionapp.com/d/main#/console/7265910/201538378/preview
- **NEW** - Add Group Form
  + Located as another tab of the general + upper right Menu
  + https://projects.invisionapp.com/d/main#/console/7265910/201540525/preview
  + https://projects.invisionapp.com/d/main#/console/7265910/201546276/preview
  + https://projects.invisionapp.com/d/main#/console/7265910/201546278/preview
- **UPDATED** - Share Settings for Tip/Hive/SubHive
  + Need a design to show update

##### API
- New Groups model
  + Followable (hive can follow, user can follow) through share interface
  + `rails g model Group name:string{null:false} avatar:string avatar_tmp:string avatar_processing:boolean color_index:integer{default: 8}`
- Controllers
  + GroupController Create, List (scoped to user), Delete
  + Maybe GroupMemberController? Create = join, Destroy = Leave, Index = List of members, etc...
- Serializers
  + Group: id, name, color_index, user_followers, hive_followers, tip_followers

##### TESTS
- Given a Hive Shared with Group A
- And Bob is a member of Group A
- And Bob Clicks the Group A Tab
  + Then Bob should see the Hive in his left Menu

- Given a Hive is **NOT** Shared with Group A
- And Bob is a member of Group A
- And Bob Clicks the Group A Tab
  + Then Bob should **NOT** see the Hive in his left Menu

- Given a Tip is shared with Group A
- And Bob is a member of Group A
- And Bob clicks the Group A Tab
  + Then Bob should see the tip in the TipFeed

- Given a Tip is **NOT** shared with Group A
- And Bob is a member of Group A
- And Bob clicks the Group A Tab
  + Then Bob should **NOT** see the tip in the TipFeed

- Given a Hive Shared with Group A
- And a Tip within Hive A is **NOT** shared with Group A
- And Bob is a member of Group A
- And Bob Clicks the Group A Tab
- And Bob Clicks the Hive link to open the Hive
  + Then Bob should **NOT** see the Tip

- Given Bob is viewing his Home TipFeed
- And Tip A is shared directly with Bob
- And Tip B is shared with Group A
- And Bob is a member of Group A
  + Then Bob should see Tip A
  + Then Bob should see Tip B

- Given Bob is viewing his Home TipFeed
- And Tip A is shared directly with Bob
- And Tip B is shared with Group A
- And Bob is a member of Group A
- And Bob Clicks the Group A Tab
  + Then Bob should **NOT** see Tip A
  + Then Bob should still see Tip B
