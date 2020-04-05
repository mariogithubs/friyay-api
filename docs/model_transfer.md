### BREAKDOWN OF MODELS
#### Users -> Users
---
###### New users table
| Old Field                | New Field            | Notes              |
| :----------------------: | :------------------: | ------------------ |
| id                       | id                   |                    |
| email                    | email                |                    |
| encrypted_password       | encrypted_password   |                    |
| reset_password_token     | VALUE = NULL         | RESET ALL OF THESE |
| reset_password_sent_at   | VALUE = NULL         | RESET              |
| remember_created_at      | VALUE = NULL         | RESET              |
| sign_in_count            | sign_in_count        |                    |
| current_sign_in_at       | current_sign_in_at   |                    |
| last_sign_in_at          | last_sign_in_at      |                    |
| current_sign_in_ip       | current_sign_in_ip   |                    |
| last_sign_in_ip          | last_sign_in_ip      |                    |
| confirmation_token       | VALUE = NULL         | RESET              |
| confirmed_at             | VALUE = NULL         | RESET              |
| confirmation_sent_at     | VALUE = NULL         | RESET              |
| unconfirmed_email        | VALUE = NULL         | RESET              |
| failed_attempts          | failed_attempts      |                    |
| unlock_token             | VALUE = NULL         | RESET              |
| locked_at                | VALUE = NULL         | RESET              |
| created_at               | created_at           |                    |
| updated_at               | updated_at           |                    |
| invitation_token         | NONE                 | TO BE DETERMINED   |
| invitation_created_at    | NONE                 | TO BE DETERMINED   |
| invitation_sent_at       | NONE                 | TO BE DETERMINED   |
| invitation_accepted_at   | NONE                 | TO BE DETERMINED   |
| invitation_limit         | NONE                 | TO BE DETERMINED   |
| invited_by_id            | NONE                 | TO BE DETERMINED   |
| invited_by_type          | NONE                 | TO BE DETERMINED   |
| invitations_count        | NONE                 | TO BE DETERMINED   |
| first_name               | first_name           |                    |
| last_name                | last_name            |                    |
| avatar                   | NONE                 | MOVED TO PROFILE   |
| username                 | username             |                    |
| background_image         | NONE                 | MOVED TO PROFILE   |
| background_image_top     | NONE                 | MOVED TO PROFILE   |
| background_image_left    | NONE                 | MOVED TO PROFILE   |
| roles_mask               | NONE                 | UNUSED             |
| daily_sent_at            | NONE                 | MOVED TO PROFILE   |
| weekly_sent_at           | NONE                 | MOVED TO PROFILE   |
| authentication_token     | NONE                 | DEPRECATED         |
| role                     | NONE                 | UNUSED             |
| second_email             | second_email         |                    |
| color                    | NONE                 | MOVED TO PROFILE   |
| is_show_tour             | NONE                 | DEPRECATED         |

#### Users -> UserProfile
---
###### New users table
| Old Field                | New Field            | Notes              |
| :----------------------: | :------------------: | ------------------ |
| id                       | user_id              | NEW FOR THIS TABLE |
| avatar                   | avatar               | MOVED TO PROFILE   |
| background_image         | background_image     | MOVED TO PROFILE   |
| background_image_top     | nil                  | MOVED TO PROFILE   |
| background_image_left    | nil                  | MOVED TO PROFILE   |
| daily_sent_at            | nil                  | MOVED TO PROFILE   |
| weekly_sent_at           | nil                  | MOVED TO PROFILE   |
| color                    | nil                  | MOVED TO PROFILE   |
| created_at               | created_at           |                    |
| updated_at               | updated_at           |                    |

#### Settings -> Settings
---
- NOT IMPORTING< USING DEFAULTS

#### Domains -> Domains
---
- Do not import where active == 0
- Make sure to make the domain creator a domain member
- make sure to make is_public False
| Old Field  |    New Field     |          Notes           |
|------------|------------------|--------------------------|
| id         | id               |                          |
| name       | name             |                          |
| logo       | logo             |                          |
| background | background_image |                          |
| active     | NONE             | DEPRECATED               |
| user_id    | user_id          |                          |
| created_at | created_at       |                          |
| updated_at | updated_at       |                          |
| NONE       | is_public        | NEW FIELD DEFAULT: FALSE |
| NONE       | tenant_name      | NEW FIELD                         |

#### Hives -> Topics
---
- Set color to index (ON TOPICS PREFS)
###### New topics table
|       Old Field       |       New Field        |                  Notes                   |
|-----------------------|------------------------|------------------------------------------|
| id                    | id                     |                                          |
| user_id               | user_id                |                                          |
| title                 | title                  |                                          |
| description           | description            |                                          |
| created_at            | created_at             |                                          |
| updated_at            | updated_at             |                                          |
| is_public             | share_public           | TOPIC PREFS new field                    |
| background_color      | background_color_index | MOVED TO TOPIC PREFERENCES               |
| background_image      | background_image       | MOVED TO TOPIC PREFERENCES               |
| shared_all_friends    | share_following        | TOPIC PREFS new field                    |
| is_on_profile         | nil                    | UNUSED                                   |
| allow_add_pocket      | nil                    | UNUSED                                   |
| allow_friend_share    | nil                    | UNUSED                                   |
| pictures_count        | nil                    | UNUSED - will regenerate if needed       |
| slug                  | nil                    | slugs are auto generated dynamically     |
| sharing_type          | nil                    | deprecated in favor of new methods       |
| is_private            | nil                    | a topic cannot be private                |
| shared_select_friends | nil                    | deprecated in favor of new methods       |
| domain_id             | nil                    | NO LONGER REQUIRED WITH NEW ARCHITECTURE |
|                       |                        | Use this to determine tenant             |
| NONE                  | ancestry               | NEW FIELD. ASSIGN BLANK ON IMPORT        |

#### Shares -> ShareSettings
---

|       Old Field       |       New Field       | Notes |
|-----------------------|-----------------------|-------|
| id                    | id                    |       |
| shareable_object_type | shareable_object_type |       |
| shareable_object_id   | shareable_object_id   |       |
| sharing_object_type   | sharing_object_type   |       |
| sharing_object_id     | sharing_object_id     |       |
| user_id               | user_id               |       |
| created_at            | created_at            |       |
| updated_at            | updated_at            |       |

#### ObjectSettings -> TopicPreferences
---
- During one of the imports, we may need to change the share_following to true if share is that list

|      Old Field      |       New Field        |         Notes          |
|---------------------|------------------------|------------------------|
| object_setting_id   | topic_id               |                        |
| object_setting_type | nil                    | UNUSED                 |
| user_id             | user_id                |                        |
| is_private          | share_public           | INVERT SETTING         |
| background_image    | background_image       |                        |
| created_at          | created_at             |                        |
| updated_at          | updated_at             |                        |
| domain_id           | nil                    | USE TO FILTER TENANT   |
| nil                 | background_color_index | USE DEFAULT FOR IMPORT |
| nil                 | share_following        | USE DEFAULT FOR IMPORT  |
|                     |                        |                        |

#### Pockets -> SubTopics
---
**NOTE: For each topic a pocket follows, we must create a new subtopic with the same information**
- Subtopics will get brand new shiny IDs, their old id will be used during import to connect resources
- We don't need to import topic preferences for subtopics
- When we import follows, we will assign ancestry
###### New topics table
|       Old Field       |    New Field    |              Notes               |
|-----------------------|-----------------|----------------------------------|
| id                    | old_subtopic_id | USE THIS TO MAKE OLD CONNECTIONS |
| title                 | title           |                                  |
| description           | description     |                                  |
| created_at            | created_at      |                                  |
| updated_at            | updated_at      |                                  |
| user_id               | user_id         |                                  |
| is_public             | nil             | UNUSED                           |
| is_on_profile         | nil             | UNUSED                           |
| allow_add_tip         | nil             | UNUSED                           |
| allow_friend_share    | nil             | UNUSED                           |
| slug                  | nil             | slugs are auto generated         |
| background_image      | nil             | UNUSED                           |
| is_asking_for_tips    | nil             | UNUSED                           |
| is_private            | nil             | a topic cannot be private        |
| shared_all_friends    | nil             | moved to prefs                   |
| shared_select_friends | nil             | UNUSED                           |
| domain_id             | nil             | DEPRECATED                       |
| FROM FOLLOW TABLE     | ancestry        | SPECIAL RULES APPLY TO THIS*     |

###### The following applies to the pocket -> subtopic transition
- Topics may have many children subtopics
- A subtopic can only have one root topic
- Because we didn't have nested subtopics, we can assume that each hive a pocket followed can translate into the parent_id of the pocket
- Because we allowed a pocket to follow multiple topics, we'll create a duplicate subtopic for each topic that the pocket was following.
- we'll need a way for tips to find their subtopics. we'll probably need an old_subtopic_id field to temporarily use as a lookup field to connect tips to their new subtopics

#### Tips -> Tips
---
- Set color to index

|       Old Field       |    New Field    | Notes |
|-----------------------|-----------------|-------|
| id                    | id              |       |
| title                 | title           |       |
| description           | body            |       |
| user_id               | user_id         |       |
| parent_id             | nil             |       |
| lft                   | nil             |       |
| rgt                   | nil             |       |
| created_at            | created_at      |       |
| updated_at            | updated_at      |       |
| is_public             | share_public       |       |
| longitude             | nil             |       |
| latitude              | nil             |       |
| address               | nil             |       |
| location              | nil             |       |
| pictures_count        | nil             |       |
| comments_count        | nil             |       |
| slug                  | nil             |       |
| cached_votes_total    | nil             |       |
| cached_votes_score    | nil             |       |
| cached_votes_up       | nil             |       |
| cached_votes_down     | nil             |       |
| cached_weighted_score | nil             |       |
| sharing_type          | nil             |       |
| question_id           | nil             |       |
| links_count           | nil             |       |
| is_private            | nil      |       |
| shared_all_friends    | share_following |       |
| shared_select_friends | nil             |       |
| domain_id             | nil             |       |
| deleted_at            | nil             |       |
| destroyer_id          | nil             |       |
| access_key            | nil             |       |
| draft                 | nil             |       |
| color                 | nil             |       |
|                       |                 |       |

#### Questions -> Questions
---
- change is_public to share_public
- add share_following 

|       Old Field       |    New Field    | Notes |
|-----------------------|-----------------|-------|
| id                    | id              |       |
| name                  | body            |       |
| user_id               | user_id         |       |
| created_at            | created_at      |       |
| updated_at            | updated_at      |       |
| library               | nil             |       |
| sent_at               | nil             |       |
| comments_count        | nil             |       |
| sharing_type          | nil             |       |
| cached_votes_total    | nil             |       |
| cached_votes_score    | nil             |       |
| cached_votes_up       | nil             |       |
| cached_votes_down     | nil             |       |
| cached_weighted_score | nil             |       |
| is_public             | share_public    |       |
| is_private            | nil             |       |
| shared_all_friends    | share_following |       |
| shared_select_friends | nil             |       |
| domain_id             | nil             |       |
| access_key            | nil             |       |
| pictures_count        | nil             |       |
| color                 | nil             |       |
| anonymously           | nil             |       |

#### Comments -> Comments
---

|    Old Field     |    New Field     | Notes |
|------------------|------------------|-------|
| id               | id               |       |
| commentable_id   | commentable_id   |       |
| commentable_type | commentable_type |       |
| title            | title            |       |
| body             | body             |       |
| subject          | subject          |       |
| user_id          | user_id          |       |
| parent_id        | parent_id        |       |
| lft              | lft              |       |
| rgt              | rgt              |       |
| created_at       | created_at       |       |
| updated_at       | updated_at       |       |
| longitude        | longitude        |       |
| latitude         | latitude         |       |
| address          | address          |       |
| location         | location         |       |
| domain_id        | nil              |       |

#### Pictures -> Attachments
---
-- may need to clean up attachable_type HIVE and POCKET
|   Old Field    |    New Field    | Notes |
|----------------|-----------------|-------|
| id             | id              |       |
| user_id        | user_id         |       |
| image          | file            |       |
| image_type     | nil             |       |
| imageable_id   | attachable_id   |       |
| imageable_type | attachable_type |       |
| title          | nil             |       |
| created_at     | created_at      |       |
| updated_at     | updated_at      |       |
| domain_id      | nil             |       |

#### FileUploads -> Attachments
---
-- may need to clean up attachable_type HIVE and POCKET
|   Old Field   |    New Field    | Notes |
|---------------|-----------------|-------|
| id            | id              |       |
| user_id       | user_id         |       |
| file          | file            |       |
| fileable_id   | attachable_id   |       |
| fileable_type | attachable_type |       |
| title         | nil             |       |
| created_at    | created_at      |       |
| updated_at    | updated_at      |       |
| domain_id     | nil             |       |

#### Follows -> Follows
---
- Import this after Topic b/c we will be referencing it and changing things
- Change 'Hive' to 'Topic' during import LEAVE Pocket alone for now
- 

|    Old Field    |    New Field    | Notes  |
|-----------------|-----------------|--------|
| id              | id              |        |
| followable_id   | followable_id   |        |
| followable_type | followable_type |        |
| follower_id     | follower_id     |        |
| follower_type   | follower_type   |        |
| blocked         | blocked         |        |
| created_at      | created_at      |        |
| updated_at      | updated_at      |        |
| reason          | nil             | UNUSED |
| message         | nil             | UNUSED |


#### Votes -> Votes
---
|  Old Field   |  New Field   | Notes |
|--------------|--------------|-------|
| id           | id           |       |
| vote_flag    | vote_flag    |       |
| votable_id   | votable_id   |       |
| votable_type | votable_type |       |
| voter_id     | voter_id     |       |
| voter_type   | voter_type   |       |
| created_at   | created_at   |       |
| updated_at   | updated_at   |       |
| vote_weight  | vote_weight  |       |
| vote_scope   | vote_scope   |       |
| domain_id    | nil          |       |

###### Notes
- Make sure to connect users to follow hives they created