## Users

filter options: [:following]

users: { following: [{id: 1, type: 'users' },{},...], not_following: [{},{}] }

#### Authentication
- When you successfully login, you will get back an auth token
  + This uses a special UserAuthenticatedSerializer that returns information we don't want sent when a user is included with other objects

#### Relevent Gems
- devise
- simple_token_authentication
- doorkeeper
- acts_as_follwer

#### TipHive Libraries in use

#### Definitions/Rules
- If a subtopic is shared with a user, then the user must also follow its root topic(Hive)
