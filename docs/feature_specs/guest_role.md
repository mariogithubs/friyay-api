#### Guest Role

<h4 style='color: red;'>DRAFT</h4>

**Updated: {todays' date}**

**Work Estimate: {Range of days}**

#### PURPOSE
- To allow a user to access very controlled information on a domain

#### Question
- Should we allow admins to restrict inviting people as members?
  + They would only be able to invite as a guest
  + The admin can Change the role to member if needed

#### DESCRIPTION
##### BEHAVIOR
- A user should be able to invite a person and give them a guest role
- Once a user is a Guest, only an admin? an make them a Domain Member
- By default, guests can see tips shared with them specifially, not "Everyone"
  - An option exists to restrict guests to see only tips, hives, people shared with a group they belong to

#### DEVELOPMENT THOUGHTS
##### API
- Lots of work here to create a new role for guests and ensure permissions and viewability is correct
- Need to be able to assign a role to a user
- Need Permissions to restrict to a group

##### FRONT END
- Need to add type of invitation to invitation
- Need to add interface for setting guest permissions
- Need to add alerts for when a guess is not allowed to view something?
  + When would this even come up?

##### TESTS
- Given I am an admin
  + I should be able to change a user's role to Guest or Member
- Given I am a member
  + I should be able to invite someone as a guest
- Given I am a Guest
  + And my permissions allow me to see any domain content shared with me
    * Then if someone creates a tip and shares with me outside a group, I should see it
- Given I am a Guest
  + And my permissions only allow me to see content in groups I belong to
    * Then if someone shares a tip with a group I am in, I should see it
    * Then if someone shares a tip with a group I am NOT in, I should NOT see it
