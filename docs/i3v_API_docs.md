##### TIPHIVE API v2.0 #####

### Table Of Contents
- [Users](#users-people)
- [User Profiles](#user-profile)
- [Topics](#topics)
- [Tips](#tips)
- [TipLinks](#tip_links)
- [Questions](#questions)
- [Comments](#comments-answers)
- [Groups](#groups)
- [Search](#search)
- [Sharing](#sharing)
- [Follow/Unfollow](#follow-unfollow)
- [Flags](#flags)
- [Likes](#likes)
- [Votes](#votes)
- [Invitations](#invitations)


### USERS/PEOPLE
---

#### GET `/users/explore`
*List of users following the same hives and not being followed by default*

|     param     |                  value                   | req? |                            notes                             |
|---------------|------------------------------------------|------|--------------------------------------------------------------|
| filter[users] | following, followers, all                | no   | changes which users are returned. removes 'same hives' scope |
| EXAMPLE       | `/users/explore?filter[users]=following` | ---  |                                                              |

#### GET `/users`
*List of users. Defaults to current_user.following*

|        param        |                  value                   | req? |                         notes                          |
|---------------------|------------------------------------------|------|--------------------------------------------------------|
| filter[users]       | following, followers, all, not_following | no   | if not_following, will find users following same hives |
| EXAMPLE             | `/users?filter[users]=following`         | ---  |                                                        |
| filter[users][name] | first, last, or email to find            | no   |                                                        |
|                     | `/users?filter[users][name]=bob`         |      | will find users with first_name, last_name or email having 'bob' inside                                                       |

#### POST `/users/:id/follow`
*Current user will follow the user with the given :id*

#### POST `/users/:id/unfollow`
*Current user will stop following the user with the given :id*

#### POST `/users/:id/follow_all_topics`
*Current user will follow the topics the given user is following*
- If User A is following Topics 3,4,5 and User B follows User A then User B will be now follow Topics 3,4,5

### USER PROFILE
---
#### POST `/users/:user_id/user_profile`
*Update user and profile*

- For updating email notifications send array of hash email_notifcations: { someone_likes_question: 'weekly', someone_add_tip_to_topic: 'daily' }

- Available options for notification keys [
  :someone_likes_tip,
  :someone_likes_question,
  :someone_add_tip_to_topic,
  :someone_shared_topic_with_me,
  :someone_shared_tip_with_me,
  :someone_shared_question_with_me,
  :someone_comments_on_tip,
  :someone_added_to_group,
  :someone_added_to_domain,
  :someone_commented_on_tip_user_commented
]

- Available options for notification frequency value is %w(always daily weekly never)

|              param                                  |   value       | req? |   example   |              notes                       |
|-----------------------------------------------------|---------------|------|-------------|------------------------------------------|
| email_notifcations                                  |  hash         | no   |             |  someone_likes_question: 'weekly'        |
| attributes[avatar]                                  |  file         | no   |             |                                          |
| attributes[background_image]                        |  file         | no   |             |                                          |
| attributes[remote_avatar_url]                       |  link         | no   |             |                                          |
| attributes[remote_background_image_url]             |  link         | no   |             |                                          |
| attributes[follow_all_members]                      |  boolean      | no   |             |                                          |
| attributes[follow_all_hives]                        |  boolean      | no   |             |                                          |
| attributes[user_attributes][id]                     |  integer      | yes  |             |                                          |
| attributes[user_attributes][first_name]             |  string       | no   |             |                                          |
| attributes[user_attributes][last_name]              |  string       | no   |             |                                          |
| attributes[user_attributes][email]                  |  string       | no   |             |                                          |
| attributes[user_attributes][password]               |  string       | no   |             |                                          |
| attributes[user_attributes][password_confirmation]  |  string       | no   |             | required when changing password          |
| attributes[user_attributes][current_password]       |  string       | no*  |             | required when changing email or password |

#### POST `/user_profile/:id/notification_frequency`
*Update notification_frequency*

|  param  | value  | req? | example | notes |
|---------|--------|------|---------|-------|
| user_id | id     | yes  |         |       |
| type    | string | yes  |         |       |
| value   | string | yes  |         |       |




### TOPICS
---
#### TOPICS -- CRUD Operations
---
#### GET `/topics`
*List of current user connected hives (my_hives)*
- Defaults to **current_user.following_topics.roots** (The hives a the user is following)

|      param      |    value     | req? |                example                 |                                              notes                                              |
|-----------------|--------------|------|----------------------------------------|-------------------------------------------------------------------------------------------------|
| parent_id       | a topic id   | no   | `/topics?parent_id=1`                  | Use this when viewing a Hive to get `subtopics. Only subtopics of topic with parent_id will show |`
| sort[fieldname] | asc or desc  | no   | `/topics?sort[created_at]=desc`        | topics sorted by field                                                                          |
| page[number]    | page number  | no   | `/topics?page[number]=1`               |                                                                                                 |
| page[size]      | # of records | no   | `/topics?page[number]=1&page[size]=10` |                                                                                                 |

#### GET `/topics/:id`
*Show a topic detail*

``` json
{
  "data": {
    "id": "10",
    "type": "topics",
    "attributes": {
      "title": "Recruitment",
      "description": "",
      "slug": "10-recruitment",
      "user_id": 2,
      "created_at": "2012-01-01T12:00:00.000Z",
      "path": [
        {
          "id": 10,
          "type": "topics",
          "title": "Recruitment",
          "slug": "10-recruitment"
        }
      ],
      "kind": "Hive"
    },
    "relationships": {
      "parent": {
        "data": null
      },
      "children": {
        "data": [
          {
            "id": "3292",
            "type": "topics"
          },
          {
            ...
          }
        ]
      },
      "topic_preferences": {
        "data": [
          {
            "id": 11456,
            "type": "topic_preferences",
            "background_color_index": 1,
            "background_image_url": null,
            "share_following": false,
            "share_public": true
          }
        ]
      },
      "share_settings": {
        "data": [
          null, // RETURN null if object can't be found
          {
            "id": 20,
            "sharing_object_id": 6629,
            "sharing_object_type": "User",
            "sharing_object_name": "Perry Keys",
            "shareable_object_avatar": null
          },
          {
            ... // Repeat for each sharing object
          }
        ]
      },
      "question_followers": {
        "data": []
      },
      "user_followers": {
        "data": [
          {
            "id": "6873",
            "type": "users"
          },
          {
            ...
          }
        ]
      },
      "group_followers": {
        "data": []
      },
      "list_followers": {
        "data": []
      }
    }
  }
}
```

#### TOPICS -- Sharing
---
*See the create/update options for topics*
*You must include relationships data in request*
- Send a list of ids to follow, API will remove/add appropriate connections

###### Topic Sharing Specs:
- Remember: This is ONLY to provide a way to affect the current_users Tips
  + You "share" all tips in hive by changing settings
  + The settings then become the default for new tips
  + This is an additive process only. You cannot remove settings for a tip
- Share Setting Behavior
  + You must create a new share setting when a user is selected
  + You must remove the share setting when a user is de-selected
- Follow Behavior
  + You may create a new follow when a user is selected
  + You may not remove a follow when a user is de-selected

#### TOPICS -- Other
---
#### GET `/topics/explore`
*List of Hives to be explored*
- The topic list is currently topics followed by EDITOR_EMAIL
- The default filter is topics not being followed

|     param      |     value     | req? |                    example                     |   notes    |
|----------------|---------------|------|------------------------------------------------|------------|
| filter[topics] | not_following | no   | `/topics/explore?filter[topics]=not_following` | Future Use |
| page[number]   | page number   | no   | `/topics/explore?page[number]=1`               |            |
| page[size]     | # of records  | no   | `/topics/explore?page[number]=1&page[size]=10` |            |

#### GET `/topics/suggested_topics`
*A list of suggested titles of topics*

#### Response Format:
``` json
{
  "data": [
    {
      "id": global_template.id,
      "type": 'global_templates',
      "attributes": {
        "title": global_template.title
      }
    },
    {...}, {...}
  ]
}
```

#### GET `/topics/:topic_id/tips`
*Get `a list of tips that belong to a topic with :id*`

#### GET `/topics/:topic_id/questions`
*Get `a list of questions that belong to a topic with :id*`

#### POST `/topics`
*Create a topic*
*Params listed below are typically sent via JSON payload*

|              param                                                |   value      | req? | example |   notes                    |
|-------------------------------------------------------------------|--------------|------|---------|----------------------------|
| title                                                             | string       | yes  |         |                            |
| description                                                       | text         | no   |         |                            |
| parent_id                                                         | a topic id   | no   |         | creates a subtopic         |
| relationships[topic_preferences]                                  | array of hash| yes* |         | not required,  recommended |
| relationships[topic_preferences][0][data][background_image]       | image        | no   |         |                            |
| relationships[topic_preferences][0][data][background_color_index] | image        | no   |         |                            |
| relationships[topic_preferences][0][data][share_following]        | image        | no   |         |                            |
| relationships[topic_preferences][0][data][share_public]           | image        | no   |         |                            |
| relationships[group_followers]                                    | array        | no   |         |                            |
| relationships[user_followers]                                     | array        | no   |         |                            |
| relationships[list_followers]                                     | array        | no   |         |                            |

#### PATCH `/topics/[:id]`
*Update an existing topic*
*Params listed below are typically sent via JSON payload*

|                               param                               |      value      | req? |           notes            |   |
|-------------------------------------------------------------------|-----------------|------|----------------------------|---|
| id                                                                | topic id        | yes  |                            |   |
|                                                                   | `/topics/1`     |      |                            |   |
| title                                                             | string          | yes  |                            |   |
| description                                                       | text            | no   |                            |   |
| parent_id                                                         | a topic id      | no   | creates a subtopic         |   |
| relationships[topic_preferences]                                  | array of hash   | yes* | not required,  recommended |   |
| relationships[topic_preferences][0][data][background_image]       | image           | no   |                            |   |
| relationships[topic_preferences][0][data][background_color_index] | image           | no   |                            |   |
| relationships[topic_preferences][0][data][share_following]        | image           | no   |                            |   |
| relationships[topic_preferences][0][data][share_public]           | image           | no   |                            |   |
| relationships[group_followers][data]                              | array of hashes | no   |                            |   |
| relationships[user_followers][data]                               | array of hashes | no   |                            |   |
| relationships[list_followers][data]                               | array of hashes | no   |                            |   |


#### POST `/topics/[:id]/join`
*Join (follow) a topic*

#### DELETE `/topics/[:id]`
*Remove a topic with all sub topics*

|              param                                                |   value      | req? |   example   |           notes            |
|-------------------------------------------------------------------|--------------|------|-------------|----------------------------|
| id                                                                | topic id     | yes  | `/topics/1` |                            |
| notify                                                            | boolean      | no   |             |   notify followers         |
| alternate_topic_id                                                | integer      | no   |             |   move tips to this topic  |
| move_tip_ids                                                      | :all/Array   | no   |             | all/Array tip ids to move  |

#### POST `/topics/[:id]/move`
*Move subtopic*

|              param                                     |   value      | req? |   example   |           notes                |
|--------------------------------------------------------|--------------|------|-------------|--------------------------------|
| id                                                     | topic id     | yes  | `/topics/1` |                                |
| alternate_topic_id                                     | integer      | yes  |             |   move subtopic to this topic  |

#### POST `/topics/[:id]/share_with_relationships`
*Share a topic with provided relationships*
- Relationships should be provided in the json data payload

<a name="tip_flag"></a>
<!-- An anchor for some docs later -->

### TIPS
---
#### TIPS -- CRUD operations
---
#### GET `/tips`
*Retrieve a list of tips*

#### GET `/topics/:topic_id/tips`
*Listed here as an alternative way to retrieve tips for a specific topic*

#### POST `/tips`
*Create a new tip*

**NOTE:** user_followers can accept an option 'Everyone' and/or 'Following'

``` json
{
  "data": {
    "type": "tips",
    "attributes": {
      "title": "Tip Title",
      "body": "Tip Body copy",
      "share_following": false,
      "share_public": true
    },
    "relationships": {
      "subtopics": {
        "data": [
          { "id": topic_id, "type": "topics" },
          { "id": another_topic_id, "type": "topics" }
        ]
      },
      "user_followers || list_followers || group_followers": {
        "data": [
          { "id": user_id, "type": "users || lists || groups" },
          { "id": another_user_id, "type": "users || lists || groups" }
        ]
      },
      "attachments": {
        "data": [
          { "id": attachment_id, "type": "attachments" },
          { "id": another_attachment_id, "type": "attachments" }
        ]
      }
    }
  }
}
```

|                param                 |             value             | req? |              notes               |
|--------------------------------------|-------------------------------|------|----------------------------------|
| title                                |                               | yes  |                                  |
| body                                 |                               | yes  |                                  |
| relationships[subtopics][data]       | array of topic_ids            | no   |                                  |
|                                      | {id: id, type: "topics"}      |      |                                  |
| relationships[user_followers][data]  | array of user_ids             | no   | users will follow tip            |
|                                      | {id: id, type: "users"}       |      |                                  |
|                                      | OPTIONAL id: 'Everyone'       |      | will set the tip to share_public |
|                                      | OPTIONAL id: 'Following'      |      | will set tip to share_following  |
| relationships[list_followers][data]  | array of list_ids             | no   | lists of users will follow tip   |
|                                      | {id: id, type: "lists"}       |      |                                  |
| relationships[group_followers][data] | array of group_ids            | no   | groups will follow tip           |
|                                      | {id: id, type: "groups"}      |      |                                  |
| relationships[attachments][data]     | array of attachment_ids       | no   | will connect attachments to tip  |
|                                      | {id: id, type: "attachments"} |      |                                  |

#### PATCH `/cards/:id`
*Update a certain tip*
*See Create for a list of attributes*

#### DELETE `/cards/:id`
*Delete a certain tip*

#### TIPS -- Share Settings
---
*See the create/update options for tips*
*You must include relationships data in request*
- Send a list of ids to follow, API will remove/add appropriate connections

#### TIPS -- Flag, like, vote
---
#### POST `/cards/:id/flag`
*Flag a tip with reason*

```
{
  data: {
    id: tip.id,
    type: 'tips',
    reason: 'Flagger Reason'
  }
}
```

|    param     |                      value                       | req? |                notes                 |
|--------------|--------------------------------------------------|------|--------------------------------------|
| id           | tip id                                           | yes  |                                      |
| reason       | string                                           | no   | reason for flagging                  |

#### POST `/cards/:id/like`
*Like a tip*

|    param     |                      value                       | req? |                notes                 |
|--------------|--------------------------------------------------|------|--------------------------------------|
| id           | tip id                                           | yes  |                                      |

#### POST `/cards/:id/unlike`
*Like a tip*

|    param     |                      value                       | req? |                notes                 |
|--------------|--------------------------------------------------|------|--------------------------------------|
| id           | tip id                                           | yes  |                                      |

#### POST `/cards/:id/upvote`
*Upvote a tip*

|    param     |                      value                       | req? |                notes                 |
|--------------|--------------------------------------------------|------|--------------------------------------|
| id           | tip id                                           | yes  |                                      |

#### POST `/cards/:id/downvote`
*Downvote a tip*

|    param     |                      value                       | req? |                notes                 |
|--------------|--------------------------------------------------|------|--------------------------------------|
| id           | tip id                                           | yes  |                                      |

### TIPLINKS
---
#### POST `/cards/:tip_id/tip_links/fetch`
*Fetch or create tip link for a tip*

|    param     |                      value                       | req? |                notes                 |
|--------------|--------------------------------------------------|------|--------------------------------------|
| tip_id       | tip id                                           | yes  |                                      |
| data[url]    | url                                              | yes  |                                      |

#### DELETE `/tip_links/:id`
*Destroy a tip link*

### SEARCH
---
#### NOTES:
- Search is scoped by domain
- IMPORTANT!!! CURRENLY USERS ARE NOT SCOPED BY DOMAIN

#### GET `/search`
*Allows us to search all or select resources*

|    param     |                      value                       | req? |                notes                 |
|--------------|--------------------------------------------------|------|--------------------------------------|
| q            | search string                                    | yes  | used alone will search all resources |
| EXAMPLE      | `/search?q=puppy`                                | ---  | ---                                  |
| resources    | one or more of user, topic, tip, group, question | no   | will only search for given resources |
| EXAMPLE      | `/search?q=puppy&resource=topic,tip`             | ---  | ---                                  |
| page[number] | integer                                          | no   | triggers pagination                  |
| EXAMPLE      | `/search?q=puppy&page[number]=1`                 | ---  | ---                                  |
| page[size]   | integer                                          | no   | changes how many results per page    |
| EXAMPLE      | `/search?q=puppy&page[number]=1&page[size]=5`    | ---  | ---                                  |



### COMMENTS/ANSWERS
---
#### GET `/cards/:tip_id/comments`
*List of comments belonging to a tip*

#### GET `/questions/:question_id/comments`
*List of answers(comments) belonging to a question*

#### POST `/cards/:tip_id/comments OR /questions/:question_id/comments`
*Create a comment to a tip*

**NOTE:** location params are not supported at this time. They may never be

|   param   |   value   | req? |     notes     |
|-----------|-----------|------|---------------|
| title     | title     | no   |               |
| body      | body      | yes  |               |
| latitude  | latitude  | no   | NOT SUPPORTED |
| longitude | longitude | no   | NOT SUPPORTED |
| location  | location  | no   | NOT SUPPORTED |

#### PATCH `/comments/:id`
*UPDATE an existing comment*

|   param   |   value   | req? |     notes     |
|-----------|-----------|------|---------------|
| title     | title     | no   |               |
| body      | body      | yes  |               |

#### POST `/comments/:id/reply`
*Create a replay to an existing comment*

|   param    | value | req? |                    notes                    |
|------------|-------|------|---------------------------------------------|
| comment_id |       | yes  | The comment to which the reply should apply |
| title      | title | no   |                                             |
| body       | body  | yes  |                                             |

#### DELETE /comments/:comment_id
**

#### POST `/comments/:id/flag`
*Flag a comment with reason*

|    param     |                      value                       | req? |                notes                 |
|--------------|--------------------------------------------------|------|--------------------------------------|
| id           | comment id                                       | yes  |                                      |
| reason       | string                                           | no   | reason for flagging                  |

### GROUP
---
#### GET `/groups`
*A list of groups the current user is following(member of)*

#### POST `/groups/:id/join`
*Allows current_user to join a group with :id*

| URL params |      value      | req? | notes |
|------------|-----------------|------|-------|
| id         | group id        | yes  |       |
|            | `groups/1/join` |      |       |

#### POST `/groups/:id/add_user`
*Adds a user to the group specified in :id*

|   JSON ONLY params   |  value  | req? | notes |
|----------------------|---------|------|-------|
| user_followers[id]   | user_id | yes  |       |
| user_followers[type] | 'users' | yes  |       |

### SEARCH
---
#### NOTES:
- Search is scoped by domain
- IMPORTANT!!! CURRENLY USERS ARE NOT SCOPED BY DOMAIN

#### GET `/search`
*Allows us to search all or select resources*

|    param     |                      value                       | req? |                notes                 |
|--------------|--------------------------------------------------|------|--------------------------------------|
| q            | search string                                    | yes  | used alone will search all resources |
| EXAMPLE      | `/search?q=puppy`                                | ---  | ---                                  |
| resources    | one or more of user, topic, tip, group, question | no   | will only search for given resources |
| EXAMPLE      | `/search?q=puppy&resource=topic,tip`             | ---  | ---                                  |
| page[number] | integer                                          | no   | triggers pagination                  |
| EXAMPLE      | `/search?q=puppy&page[number]=1`                 | ---  | ---                                  |
| page[size]   | integer                                          | no   | changes how many results per page    |
| EXAMPLE      | `/search?q=puppy&page[number]=1&page[size]=5`    | ---  | ---                                  |

### SHARING
---
- Each resources has their own share settings section look up Tips, Topics, etc...

### FOLLOW/UNFOLLOW
---

### FLAGS
---
- See [/cards/:id/flag](#user-content-tip_flag)
- Same for Comment and Question flags

### LIKES
---

### VOTES
---

### INVITATIONS
---

#### GET `/invitations`
*Retrieve a list of invitations*

#### POST `/invitations/search`
*Retrieve status of emails*

|              param               |   value           | req? |   example   |              notes               |
|----------------------------------|-------------------|------|-------------|----------------------------------|
| emails                           | Array of emails   | yes  |             | returns array of email and status|

#### POST `/invitations/create`
*Create an invitation*

|      param      | value  | req? | example |              notes               |
|-----------------|--------|------|---------|----------------------------------|
| user_id         | id     | yes  |         |                                  |
| email           | email  | yes  |         |                                  |
| invitation_type | string | yes  |         | :account, :domain, :group, :hive |
| invitable_type  | string | yes  |         |                                  |
| invitable_id    | id     | yes  |         |                                  |
| custom_message  | text   | no   |         |                                  |

#### GET `/invitations/:id/reinvite`
*Reinvite*

| param |     value     | req? | example | notes |
|-------|---------------|------|---------|-------|
| id    | invitation id | yes  |         |       |

#### POST `/invitations/request_invitation`
*Creates a new invitation where domain owner is inviter and submitted email is invitee*

|   param    |   value    | req? | example | notes |
|------------|------------|------|---------|-------|
| email      | email      | yes  |         |       |
| first_name | first name | no   |         |       |
| last_name  | last name  | no   |         |       |

### Notifications
---
#### GET `/notifications`
*Retrieve a list of notifications*
