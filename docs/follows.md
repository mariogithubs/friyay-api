# ALL ABOUT FOLLOWS, FOLLOWERS AND FOLLOWABLES
## FOLLOWS
Follows are one of the more complex conepts of the TipHive API. The idea is that anything can be made to follow anything else. For instance, a User can follow a Topic, an easy to understand concept. A more difficult concept to understand is that a Tip follows a Topic. Below, we will explain more about this with some examples.

For the purposes of this document, we will have two types of followers
    - User followers - User, Group, List
    - Resource followers - Tip, Question
    - These are not 'technically' follower types, but rather categories to help understand this document and some of the code.

#### Follows and Memberships
Sometimes we use follows to represent memberships. Domains used to be this way, but we have removed that and have created an actual domain_memberships table to hold these so they can remain outside of our Multi-Tenant system. For Groups and Lists, a user is a member if they follow that group or list.

#### Follows and Sharing
Currenlty, follows and sharing are dependencies of one another for tips. We may change this, but if you make a Tip private, we will remove any User followers from this Tip. If you make a Topic private, we will remove any User followers from tips that you created that follow that Topic, but we will not remove followers of the Topic.

This is because currently, users have a feature where they can follow or unfollow a Topic at will, but not so with Tips. 

#### Follows and Viewability
Sometimes we use follows to acts as a way to determine if someone can see a particular resource, like a Tip. We are moving more towards using permissions for this, but currently, this is how we do it.

#### Follows as they were meant to be
A user following a resource should mean that they get updates about that resource as well as having that resource show up in special lists like "Topics I am following".

When a user follows another user, magical things happen. Ok, maybe not magical, but this is the typical socail media following people are familiar with. A user following another user will get updates about new tips, questions, etc... In order to remove tips from a certain user in your TipFeed or Topic, you just unfollow that user.

#### Special Cases
There is a special case of user following user when it comes to Topics. A user may follow or unfollow a contributor within the scope of a particular hive. This would mean that if they respect what the contributor says about one Topic, but not about another, they can pick and choose which tips show up in which Hives.

#### The gem that makes it possible - acts_as_follower
Followers act as a has_many_through kind of object, where a follower can follow many followables and a followable can have many followers through the follow table. This is all possible through a gem called acts_as_follower.
- https://github.com/tcocca/acts_as_follower

This gem is out of date. We may have to use another contributors fork, or find another way to do this in the future

---

## FOLLOWERS
#### User Followers
User followers are entities that represent a user or a collection of users.

###### Models that make up User followers
- User
- Group
- List

#### Resource Followers
Resource followers are entities that represent types of resources that can follow other resources

###### Models that make up Resource followers
- Tip
- Question

---

## FOLLOWABLES
Followables are resources that can be followed. Some of these resources can act as both followable and follower, like a User. Others can only be followed, like a Topic. Followables can be followed by either User followers or Resource followers.

###### Followable Models
- Topic
- TopicPreference
- Tip
- Question
- User
- Group
- List

---

## CODE
In the API code, we are trying to consolidate commands for creating and destroying follows in a library called Connectable.rb.
